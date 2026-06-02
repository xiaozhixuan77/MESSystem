package org.example.service.impl;

import org.example.dto.request.WorkOrderCreateRequest;
import org.example.dto.request.WorkOrderUpdateRequest;
import org.example.entity.ProcessStep;
import org.example.entity.Product;
import org.example.entity.WorkOrder;
import org.example.entity.WorkOrderRouteStep;
import org.example.exception.BusinessException;
import org.example.mapper.WorkOrderMapper;
import org.example.service.ProcessStepService;
import org.example.service.ProductService;
import org.example.service.WorkOrderRouteStepService;
import org.example.service.WorkOrderService;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class WorkOrderServiceImpl extends ServiceImpl<WorkOrderMapper, WorkOrder> implements WorkOrderService {

    private static final List<String> VALID_TYPES = List.of("试产", "量产", "返工");

    private final ProductService productService;
    private final ProcessStepService processStepService;
    private final WorkOrderRouteStepService workOrderRouteStepService;

    public WorkOrderServiceImpl(ProductService productService,
                                ProcessStepService processStepService,
                                WorkOrderRouteStepService workOrderRouteStepService) {
        this.productService = productService;
        this.processStepService = processStepService;
        this.workOrderRouteStepService = workOrderRouteStepService;
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
    @Transactional
    public WorkOrder createWorkOrder(WorkOrderCreateRequest request, Long createdBy) {
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
        wo.setPlanQty(override != null && override.getPlanQty() != null
                ? override.getPlanQty() : source.getPlanQty());
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
