package org.example.service.impl;

import org.example.dto.request.WorkOrderCreateRequest;
import org.example.dto.request.WorkOrderUpdateRequest;
import org.example.dto.request.WorkOrderReportRequest;
import org.example.entity.ProcessStep;
import org.example.entity.Product;
import org.example.entity.ProductionLine;
import org.example.entity.WorkOrder;
import org.example.entity.WorkOrderRouteStep;
import org.example.exception.BusinessException;
import org.example.mapper.WorkOrderMapper;
import org.example.service.ProcessStepService;
import org.example.service.ProductService;
import org.example.service.ProductionLineService;
import org.example.service.WorkOrderRouteStepService;
import org.example.service.WorkOrderService;
import org.example.simulator.SimulatorManager;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class WorkOrderServiceImpl extends ServiceImpl<WorkOrderMapper, WorkOrder> implements WorkOrderService {

    private static final List<String> VALID_TYPES = List.of("试产", "量产", "返工");
    private static final int MAX_RETRY = 3;

    private final ProductService productService;
    private final ProcessStepService processStepService;
    private final WorkOrderRouteStepService workOrderRouteStepService;
    private final ProductionLineService productionLineService;
    private final TransactionTemplate transactionTemplate;
    private final SimulatorManager simulatorManager;

    public WorkOrderServiceImpl(ProductService productService,
                                ProcessStepService processStepService,
                                WorkOrderRouteStepService workOrderRouteStepService,
                                ProductionLineService productionLineService,
                                TransactionTemplate transactionTemplate,
                                SimulatorManager simulatorManager) {
        this.productService = productService;
        this.processStepService = processStepService;
        this.workOrderRouteStepService = workOrderRouteStepService;
        this.productionLineService = productionLineService;
        this.transactionTemplate = transactionTemplate;
        this.simulatorManager = simulatorManager;
    }

    @Override
    public List<WorkOrder> listWorkOrders(String role, Long userId, Long workshopId,
                                          String status, String type, Long lineId) {
        LambdaQueryWrapper<WorkOrder> wrapper = new LambdaQueryWrapper<>();

        if ("leader".equals(role) && workshopId != null) {
            wrapper.eq(WorkOrder::getWorkshopId, workshopId);
        } else if ("operator".equals(role)) {
            wrapper.eq(WorkOrder::getOperatorId, userId);
        }

        if (status != null && !status.isEmpty()) {
            wrapper.eq(WorkOrder::getStatus, status);
        }
        if (type != null && !type.isEmpty()) {
            wrapper.eq(WorkOrder::getType, type);
        }
        if (lineId != null) {
            wrapper.eq(WorkOrder::getLineId, lineId);
        }

        wrapper.orderByDesc(WorkOrder::getCreatedAt);
        return list(wrapper);
    }

    @Override
    public WorkOrder createWorkOrder(WorkOrderCreateRequest request, Long createdBy) {
        for (int attempt = 0; ; attempt++) {
            try {
                return transactionTemplate.execute(status ->
                        doCreateWorkOrder(request, createdBy));
            } catch (DuplicateKeyException e) {
                if (attempt >= MAX_RETRY - 1) {
                    throw new BusinessException(409, "工单号冲突，请重试");
                }
            }
        }
    }

    @Override
    @Transactional
    public WorkOrder copyWorkOrder(Long sourceId, WorkOrderCreateRequest override, Long createdBy) {
        WorkOrder source = getById(sourceId);
        if (source == null) {
            throw new BusinessException(404, "源工单不存在");
        }

        WorkOrder wo = new WorkOrder();
        wo.setCode(generateWorkOrderCode());
        wo.setType(source.getType());
        wo.setWorkshopId(source.getWorkshopId());
        wo.setLineId(source.getLineId());
        wo.setProductId(source.getProductId());
        wo.setProcessId(source.getProcessId());

        if (override != null && override.getPlanQty() != null) {
            if (override.getPlanQty() <= 0) {
                throw new BusinessException(400, "计划数量必须大于0");
            }
            wo.setPlanQty(override.getPlanQty());
        } else {
            wo.setPlanQty(source.getPlanQty());
        }

        wo.setPlanStartTime(override != null && override.getPlanStartTime() != null
                ? override.getPlanStartTime() : source.getPlanStartTime());
        wo.setPlanEndTime(override != null && override.getPlanEndTime() != null
                ? override.getPlanEndTime() : source.getPlanEndTime());
        wo.setStatus("待派工");
        wo.setSource("APP创建");
        wo.setSourceWorkorderId(sourceId);
        wo.setCreatedBy(createdBy);

        save(wo);

        List<WorkOrderRouteStep> sourceSteps = workOrderRouteStepService.lambdaQuery()
                .eq(WorkOrderRouteStep::getWorkOrderId, sourceId)
                .orderByAsc(WorkOrderRouteStep::getSeqNo)
                .list();

        if (!sourceSteps.isEmpty()) {
            List<WorkOrderRouteStep> newSteps = sourceSteps.stream().map(step -> {
                WorkOrderRouteStep rs = new WorkOrderRouteStep();
                rs.setWorkOrderId(wo.getId());
                rs.setSeqNo(step.getSeqNo());
                rs.setOpCode(step.getOpCode());
                rs.setName(step.getName());
                rs.setStationId(step.getStationId());
                return rs;
            }).collect(Collectors.toList());
            workOrderRouteStepService.saveBatch(newSteps);
        }

        return wo;
    }

    @Override
    @Transactional
    public WorkOrder updateWorkOrder(Long id, WorkOrderUpdateRequest request) {
        WorkOrder wo = getById(id);
        if (wo == null) {
            throw new BusinessException(404, "工单不存在");
        }
        if (!"待派工".equals(wo.getStatus())) {
            throw new BusinessException(400, "仅待派工状态的工单可修改");
        }

        wo.setVersion(request.getVersion());

        if (request.getType() != null) {
            if (!VALID_TYPES.contains(request.getType())) {
                throw new BusinessException(400, "工单类型必须为: 试产/量产/返工");
            }
            wo.setType(request.getType());
        }
        if (request.getWorkshopId() != null) {
            wo.setWorkshopId(request.getWorkshopId());
        }
        if (request.getLineId() != null) {
            wo.setLineId(request.getLineId());
        }
        if (request.getProductId() != null) {
            Product product = productService.getById(request.getProductId());
            if (product == null) {
                throw new BusinessException(400, "产品不存在");
            }
            if (product.getDefaultProcessId() == null) {
                throw new BusinessException(400, "该产品未配置默认工艺");
            }
            wo.setProductId(request.getProductId());
            wo.setProcessId(product.getDefaultProcessId());
        }
        if (request.getPlanQty() != null) {
            if (request.getPlanQty() <= 0) {
                throw new BusinessException(400, "计划数量必须大于0");
            }
            wo.setPlanQty(request.getPlanQty());
        }
        if (request.getPlanStartTime() != null) {
            wo.setPlanStartTime(request.getPlanStartTime());
        }
        if (request.getPlanEndTime() != null) {
            wo.setPlanEndTime(request.getPlanEndTime());
        }

        boolean updated = updateById(wo);
        if (!updated) {
            throw new BusinessException(409, "工单已被其他用户修改，请刷新后重试");
        }

        return getById(id);
    }

    @Override
    public WorkOrder getWorkOrderDetail(Long id) {
        WorkOrder wo = getById(id);
        if (wo == null) {
            throw new BusinessException(404, "工单不存在");
        }
        return wo;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void dispatch(Long workOrderId, Long operatorId) {
        WorkOrder wo = lambdaQuery()
                .eq(WorkOrder::getId, workOrderId)
                .last("FOR UPDATE")
                .one();
        if (wo == null) {
            throw new BusinessException(404, "工单不存在");
        }
        if (!"待派工".equals(wo.getStatus())) {
            throw new BusinessException(400, "只允许在\"待派工\"状态进行派工");
        }
        if (hasActiveWorkOrder(operatorId)) {
            throw new BusinessException(400, "该操作员已持有激活工单");
        }

        wo.setStatus("已派工");
        wo.setOperatorId(operatorId);
        wo.setDispatchTime(LocalDateTime.now());
        updateById(wo);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void start(Long workOrderId) {
        WorkOrder wo = lambdaQuery()
                .eq(WorkOrder::getId, workOrderId)
                .last("FOR UPDATE")
                .one();
        if (wo == null) {
            throw new BusinessException(404, "工单不存在");
        }

        boolean isDispatch = "已派工".equals(wo.getStatus());
        boolean isPaused = "暂停中".equals(wo.getStatus());
        if (!isDispatch && !isPaused) {
            throw new BusinessException(400, "工单状态不支持启动，当前: " + wo.getStatus());
        }

        Long currentUserId = getCurrentUserId();
        if (currentUserId == null || !wo.getOperatorId().equals(currentUserId)) {
            throw new BusinessException(403, "只有被指派的操作员才能开工");
        }

        ProductionLine line = productionLineService.lambdaQuery()
                .eq(ProductionLine::getId, wo.getLineId())
                .last("FOR UPDATE")
                .one();
        if (line == null) {
            throw new BusinessException(404, "产线不存在");
        }
        if (isDispatch && !"空闲".equals(line.getStatus())) {
            throw new BusinessException(400, "产线不是空闲状态，当前: " + line.getStatus());
        }
        if (isPaused && !"暂停".equals(line.getStatus())) {
            throw new BusinessException(400, "产线不是暂停状态，当前: " + line.getStatus());
        }

        wo.setStatus("生产中");
        if (isPaused) {
            wo.setPauseTime(null);
        } else {
            wo.setActualStartTime(LocalDateTime.now());
        }
        updateById(wo);

        line.setStatus("生产中");
        line.setCurrentWorkorderId(workOrderId);
        productionLineService.updateById(line);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void complete(Long workOrderId) {
        WorkOrder wo = lambdaQuery()
                .eq(WorkOrder::getId, workOrderId)
                .last("FOR UPDATE")
                .one();
        if (wo == null) {
            throw new BusinessException(404, "工单不存在");
        }
        if (!"生产中".equals(wo.getStatus())) {
            throw new BusinessException(400, "只有\"生产中\"状态才能完成生产");
        }

        Long currentUserId = getCurrentUserId();
        if (currentUserId == null || !wo.getOperatorId().equals(currentUserId)) {
            throw new BusinessException(403, "只有被指派的操作员才能完成生产");
        }

        wo.setStatus("生产完成");
        wo.setActualEndTime(LocalDateTime.now());
        updateById(wo);

        ProductionLine line = productionLineService.lambdaQuery()
                .eq(ProductionLine::getId, wo.getLineId())
                .last("FOR UPDATE")
                .one();
        if (line != null && wo.getId().equals(line.getCurrentWorkorderId())) {
            if (simulatorManager.isRunning(line.getId())) {
                simulatorManager.stop(line.getId());
            }
            productionLineService.lambdaUpdate()
                    .eq(ProductionLine::getId, line.getId())
                    .set(ProductionLine::getStatus, "空闲")
                    .set(ProductionLine::getCurrentWorkorderId, null)
                    .update();
        }
    }

    /**
     * 系统自动完工 — 产量达标时由 Tick 线程调用。
     * 跳过用户校验，不调 simulatorManager.stop()（Tick 内不能 waitForTickCompletion）。
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void autoComplete(Long workOrderId) {
        WorkOrder wo = lambdaQuery()
                .eq(WorkOrder::getId, workOrderId)
                .last("FOR UPDATE")
                .one();
        if (wo == null) {
            throw new BusinessException(404, "工单不存在");
        }
        if (!"生产中".equals(wo.getStatus())) {
            throw new BusinessException(400, "只有\"生产中\"状态才能完成生产");
        }

        wo.setStatus("生产完成");
        wo.setActualEndTime(LocalDateTime.now());
        updateById(wo);

        ProductionLine line = productionLineService.lambdaQuery()
                .eq(ProductionLine::getId, wo.getLineId())
                .last("FOR UPDATE")
                .one();
        if (line != null && wo.getId().equals(line.getCurrentWorkorderId())) {
            productionLineService.lambdaUpdate()
                    .eq(ProductionLine::getId, line.getId())
                    .set(ProductionLine::getStatus, "空闲")
                    .set(ProductionLine::getCurrentWorkorderId, null)
                    .update();
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void pause(Long workOrderId, String reason) {
        WorkOrder wo = lambdaQuery()
                .eq(WorkOrder::getId, workOrderId)
                .last("FOR UPDATE")
                .one();
        if (wo == null) {
            throw new BusinessException(404, "工单不存在");
        }
        if (!"生产中".equals(wo.getStatus())) {
            throw new BusinessException(400, "只有\"生产中\"状态才能暂停");
        }

        if (reason != null && !reason.isEmpty()) {
            String existing = wo.getExceptionNote();
            wo.setExceptionNote(existing != null ? existing + "; " + reason : reason);
        }
        wo.setStatus("暂停中");
        wo.setPauseTime(LocalDateTime.now());
        updateById(wo);

        ProductionLine line = productionLineService.lambdaQuery()
                .eq(ProductionLine::getId, wo.getLineId())
                .last("FOR UPDATE")
                .one();
        if (line != null && wo.getId().equals(line.getCurrentWorkorderId())) {
            if (simulatorManager.isRunning(line.getId())) {
                simulatorManager.stop(line.getId());
            }
            line.setStatus("暂停");
            productionLineService.updateById(line);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void resume(Long workOrderId) {
        WorkOrder wo = lambdaQuery()
                .eq(WorkOrder::getId, workOrderId)
                .last("FOR UPDATE")
                .one();
        if (wo == null) {
            throw new BusinessException(404, "工单不存在");
        }
        if (!"暂停中".equals(wo.getStatus())) {
            throw new BusinessException(400, "只有\"暂停中\"状态才能恢复");
        }

        wo.setStatus("生产中");
        updateById(wo);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void report(Long workOrderId, WorkOrderReportRequest request) {
        WorkOrder wo = lambdaQuery()
                .eq(WorkOrder::getId, workOrderId)
                .last("FOR UPDATE")
                .one();
        if (wo == null) {
            throw new BusinessException(404, "工单不存在");
        }
        if (!"生产完成".equals(wo.getStatus())) {
            throw new BusinessException(400, "只有\"生产完成\"状态才能报工");
        }
        if (request.getGood() + request.getNg() > wo.getPlanQty()) {
            throw new BusinessException(400, "良品+NG不能超过计划数量");
        }

        wo.setStatus("已报工");
        wo.setReportedQtyGood(request.getGood());
        wo.setReportedQtyNg(request.getNg());
        wo.setReportedHours(request.getHours());
        if (request.getNote() != null && !request.getNote().isEmpty()) {
            String existing = wo.getExceptionNote();
            wo.setExceptionNote(existing != null ? existing + "; " + request.getNote() : request.getNote());
        }
        updateById(wo);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void confirm(Long workOrderId) {
        WorkOrder wo = lambdaQuery()
                .eq(WorkOrder::getId, workOrderId)
                .last("FOR UPDATE")
                .one();
        if (wo == null) {
            throw new BusinessException(404, "工单不存在");
        }
        if (!"已报工".equals(wo.getStatus())) {
            throw new BusinessException(400, "只有\"已报工\"状态才能确认完工");
        }

        wo.setStatus("完工");
        wo.setActualEndTime(LocalDateTime.now());
        updateById(wo);

        if (wo.getLineId() != null) {
            ProductionLine line = productionLineService.lambdaQuery()
                    .eq(ProductionLine::getId, wo.getLineId())
                    .last("FOR UPDATE")
                    .one();
            if (line != null && workOrderId.equals(line.getCurrentWorkorderId())) {
                line.setStatus("空闲");
                line.setCurrentWorkorderId(null);
                productionLineService.updateById(line);
            }
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void scrap(Long workOrderId, String reason) {
        WorkOrder wo = lambdaQuery()
                .eq(WorkOrder::getId, workOrderId)
                .last("FOR UPDATE")
                .one();
        if (wo == null) {
            throw new BusinessException(404, "工单不存在");
        }
        if (!"暂停中".equals(wo.getStatus()) && !"已报工".equals(wo.getStatus())) {
            throw new BusinessException(400, "只有\"暂停中\"或\"已报工\"状态才能报废");
        }

        if (reason != null && !reason.isEmpty()) {
            String existing = wo.getExceptionNote();
            wo.setExceptionNote(existing != null ? existing + "; " + reason : reason);
        }
        wo.setStatus("报废");
        wo.setActualEndTime(LocalDateTime.now());
        updateById(wo);

        if (wo.getLineId() != null) {
            ProductionLine line = productionLineService.lambdaQuery()
                    .eq(ProductionLine::getId, wo.getLineId())
                    .last("FOR UPDATE")
                    .one();
            if (line != null && workOrderId.equals(line.getCurrentWorkorderId())) {
                line.setStatus("空闲");
                line.setCurrentWorkorderId(null);
                productionLineService.updateById(line);
            }
        }
    }

    private boolean hasActiveWorkOrder(Long operatorId) {
        return lambdaQuery()
                .eq(WorkOrder::getOperatorId, operatorId)
                .in(WorkOrder::getStatus, "生产中", "暂停中")
                .exists();
    }

    private Long getCurrentUserId() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }
        Object principal = authentication.getPrincipal();
        if (principal instanceof UserDetails userDetails) {
            return Long.valueOf(userDetails.getUsername());
        }
        return null;
    }

    private WorkOrder doCreateWorkOrder(WorkOrderCreateRequest request, Long createdBy) {
        if (!VALID_TYPES.contains(request.getType())) {
            throw new BusinessException(400, "工单类型必须为: 试产/量产/返工");
        }

        Product product = productService.getById(request.getProductId());
        if (product == null) {
            throw new BusinessException(400, "产品不存在");
        }
        if (product.getDefaultProcessId() == null) {
            throw new BusinessException(400, "该产品未配置默认工艺");
        }

        WorkOrder wo = new WorkOrder();
        wo.setCode(generateWorkOrderCode());
        wo.setType(request.getType());
        wo.setWorkshopId(request.getWorkshopId());
        wo.setLineId(request.getLineId());
        wo.setProductId(request.getProductId());
        wo.setProcessId(product.getDefaultProcessId());
        wo.setPlanQty(request.getPlanQty());
        wo.setPlanStartTime(request.getPlanStartTime());
        wo.setPlanEndTime(request.getPlanEndTime());
        wo.setStatus("待派工");
        wo.setSource("APP创建");
        wo.setCreatedBy(createdBy);

        save(wo);

        copyProcessStepsToRoute(wo.getId(), product.getDefaultProcessId());

        return wo;
    }

    private String generateWorkOrderCode() {
        WorkOrder last = lambdaQuery()
                .likeRight(WorkOrder::getCode, "MO")
                .orderByDesc(WorkOrder::getCode)
                .last("LIMIT 1")
                .one();
        if (last == null) {
            return "MO000001";
        }
        String numStr = last.getCode().substring(2);
        int nextNum = Integer.parseInt(numStr) + 1;
        return String.format("MO%06d", nextNum);
    }

    private void copyProcessStepsToRoute(Long workOrderId, Long processId) {
        List<ProcessStep> steps = processStepService.lambdaQuery()
                .eq(ProcessStep::getProcessId, processId)
                .eq(ProcessStep::getIsDeleted, (byte) 0)
                .orderByAsc(ProcessStep::getSeqNo)
                .list();

        if (!steps.isEmpty()) {
            List<WorkOrderRouteStep> routeSteps = steps.stream().map(step -> {
                WorkOrderRouteStep rs = new WorkOrderRouteStep();
                rs.setWorkOrderId(workOrderId);
                rs.setSeqNo(step.getSeqNo());
                rs.setOpCode(step.getOpCode());
                rs.setName(step.getName());
                rs.setStationId(step.getDefaultStationId());
                return rs;
            }).collect(Collectors.toList());
            workOrderRouteStepService.saveBatch(routeSteps);
        }
    }
}
