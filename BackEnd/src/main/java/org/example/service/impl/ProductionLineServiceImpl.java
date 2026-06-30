package org.example.service.impl;

import org.example.dto.request.CreateProductionLineRequest;
import org.example.dto.request.UpdateProductionLineRequest;
import org.example.entity.LineProcessSupport;
import org.example.entity.Process;
import org.example.entity.ProcessStep;
import org.example.entity.ProductionLine;
import org.example.entity.WorkOrder;
import org.example.entity.Workstation;
import org.example.entity.Workshop;
import org.example.exception.BusinessException;
import org.example.mapper.LineProcessSupportMapper;
import org.example.mapper.ProductionLineMapper;
import org.example.service.LineProcessSupportService;
import org.example.service.ProcessService;
import org.example.service.ProcessStepService;
import org.example.service.ProductionLineService;
import org.example.service.WorkOrderService;
import org.example.service.WorkshopService;
import org.example.service.WorkstationService;
import org.example.vo.ProductionLineVO;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.List;

@Service
public class ProductionLineServiceImpl extends ServiceImpl<ProductionLineMapper, ProductionLine> implements ProductionLineService {

    private final WorkshopService workshopService;
    private final ProcessService processService;
    private final ProcessStepService processStepService;
    private final WorkstationService workstationService;
    private final LineProcessSupportService lineProcessSupportService;
    private final WorkOrderService workOrderService;

    public ProductionLineServiceImpl(WorkshopService workshopService,
                                      ProcessService processService,
                                      ProcessStepService processStepService,
                                      WorkstationService workstationService,
                                      LineProcessSupportService lineProcessSupportService,
                                      @Lazy WorkOrderService workOrderService) {
        this.workshopService = workshopService;
        this.processService = processService;
        this.processStepService = processStepService;
        this.workstationService = workstationService;
        this.lineProcessSupportService = lineProcessSupportService;
        this.workOrderService = workOrderService;
    }

    @Override
    @Transactional
    public ProductionLineVO createLine(CreateProductionLineRequest request) {
        // 校验车间存在
        Workshop workshop = workshopService.lambdaQuery()
                .eq(Workshop::getId, request.getWorkshopId())
                .eq(Workshop::getIsDeleted, 0)
                .one();
        if (workshop == null) {
            throw new BusinessException(400, "所属车间不存在");
        }

        // 校验工艺存在
        Process process = processService.lambdaQuery()
                .eq(Process::getId, request.getCurrentProcessId())
                .eq(Process::getIsDeleted, 0)
                .one();
        if (process == null) {
            throw new BusinessException(400, "指定工艺不存在");
        }

        // 保存产线
        ProductionLine line = new ProductionLine();
        line.setName(request.getName());
        line.setWorkshopId(request.getWorkshopId());
        line.setCurrentProcessId(request.getCurrentProcessId());
        line.setStatus("空闲");
        save(line);

        // 按工艺步骤创建工作站
        List<ProcessStep> steps = processStepService.lambdaQuery()
                .eq(ProcessStep::getProcessId, request.getCurrentProcessId())
                .eq(ProcessStep::getIsDeleted, 0)
                .orderByAsc(ProcessStep::getSeqNo)
                .list();
        for (ProcessStep step : steps) {
            Workstation ws = new Workstation();
            ws.setCode("WS-" + line.getId() + "-" + step.getOpCode());
            ws.setName(step.getName());
            ws.setProductionLineId(line.getId());
            ws.setCurrentProcessId(step.getProcessId());
            ws.setDeviceStatus("待机");
            ws.setWorkStatus("空闲");
            ws.setConveyorStatus("停");
            ws.setProcessedCount(0);
            ws.setRawCount(0);
            ws.setFinishedCount(0);
            ws.setNgCount(0);
            workstationService.save(ws);
        }

        // 写入 line_process_support 关联
        LineProcessSupport lps = new LineProcessSupport();
        lps.setLineId(line.getId());
        lps.setProcessId(request.getCurrentProcessId());
        lineProcessSupportService.save(lps);

        return buildVO(line, workshop.getName());
    }

    @Override
    @Transactional
    public ProductionLineVO updateLine(Long id, UpdateProductionLineRequest request) {
        ProductionLine line = lambdaQuery()
                .eq(ProductionLine::getId, id)
                .eq(ProductionLine::getIsDeleted, 0)
                .one();
        if (line == null) {
            throw new BusinessException(404, "产线不存在");
        }

        if (!"空闲".equals(line.getStatus())) {
            throw new BusinessException(400, "只有空闲状态的产线才能编辑");
        }

        String workshopName = null;

        // 更新名称
        if (request.getName() != null && !request.getName().isBlank()) {
            line.setName(request.getName());
        }

        // 更新车间
        if (request.getWorkshopId() != null) {
            Workshop workshop = workshopService.lambdaQuery()
                    .eq(Workshop::getId, request.getWorkshopId())
                    .eq(Workshop::getIsDeleted, 0)
                    .one();
            if (workshop == null) {
                throw new BusinessException(400, "所属车间不存在");
            }
            line.setWorkshopId(request.getWorkshopId());
            workshopName = workshop.getName();
        }

        // 更新工艺
        if (request.getCurrentProcessId() != null
                && !request.getCurrentProcessId().equals(line.getCurrentProcessId())) {
            Process process = processService.lambdaQuery()
                    .eq(Process::getId, request.getCurrentProcessId())
                    .eq(Process::getIsDeleted, 0)
                    .one();
            if (process == null) {
                throw new BusinessException(400, "指定工艺不存在");
            }

            // 逻辑删除旧工作站
            workstationService.lambdaUpdate()
                    .eq(Workstation::getProductionLineId, id)
                    .eq(Workstation::getIsDeleted, 0)
                    .set(Workstation::getIsDeleted, 1)
                    .update();

            // 按新工艺步骤创建工作站
            List<ProcessStep> steps = processStepService.lambdaQuery()
                    .eq(ProcessStep::getProcessId, request.getCurrentProcessId())
                    .eq(ProcessStep::getIsDeleted, 0)
                    .orderByAsc(ProcessStep::getSeqNo)
                    .list();
            for (ProcessStep step : steps) {
                Workstation ws = new Workstation();
                ws.setCode("WS-" + line.getId() + "-" + step.getOpCode());
                ws.setName(step.getName());
                ws.setProductionLineId(id);
                ws.setCurrentProcessId(step.getProcessId());
                ws.setDeviceStatus("待机");
                ws.setWorkStatus("空闲");
                ws.setConveyorStatus("停");
                ws.setProcessedCount(0);
                ws.setRawCount(0);
                ws.setFinishedCount(0);
                ws.setNgCount(0);
                workstationService.save(ws);
            }

            // 更新 line_process_support
            lineProcessSupportService.lambdaUpdate()
                    .eq(LineProcessSupport::getLineId, id)
                    .eq(LineProcessSupport::getIsDeleted, 0)
                    .set(LineProcessSupport::getIsDeleted, 1)
                    .update();
            // 查找是否已有（含已删除的）相同关联记录，避免唯一约束冲突
            LineProcessSupport existingLps = ((LineProcessSupportMapper) lineProcessSupportService.getBaseMapper())
                    .findAnyByLineIdAndProcessId(id, request.getCurrentProcessId());
            if (existingLps != null) {
                existingLps.setIsDeleted((byte) 0);
                lineProcessSupportService.updateById(existingLps);
            } else {
                LineProcessSupport lps = new LineProcessSupport();
                lps.setLineId(id);
                lps.setProcessId(request.getCurrentProcessId());
                lineProcessSupportService.save(lps);
            }

            line.setCurrentProcessId(request.getCurrentProcessId());
        }

        updateById(line);

        // 如果没有通过更新车间得到名称，则查询
        if (workshopName == null) {
            Workshop workshop = workshopService.getById(line.getWorkshopId());
            workshopName = workshop != null ? workshop.getName() : "";
        }

        return buildVO(line, workshopName);
    }

    @Override
    @Transactional
    public void deleteLine(Long id) {
        ProductionLine line = lambdaQuery()
                .eq(ProductionLine::getId, id)
                .eq(ProductionLine::getIsDeleted, 0)
                .one();
        if (line == null) {
            throw new BusinessException(404, "产线不存在");
        }

        if (!"空闲".equals(line.getStatus())) {
            throw new BusinessException(400, "只有空闲状态的产线才能删除");
        }

        // 逻辑删除产线
        lambdaUpdate()
                .eq(ProductionLine::getId, id)
                .set(ProductionLine::getIsDeleted, 1)
                .update();

        // 逻辑删除关联工作站
        workstationService.lambdaUpdate()
                .eq(Workstation::getProductionLineId, id)
                .eq(Workstation::getIsDeleted, 0)
                .set(Workstation::getIsDeleted, 1)
                .update();

        // 逻辑删除 line_process_support
        lineProcessSupportService.lambdaUpdate()
                .eq(LineProcessSupport::getLineId, id)
                .eq(LineProcessSupport::getIsDeleted, 0)
                .set(LineProcessSupport::getIsDeleted, 1)
                .update();

        // 解除工单关联
        workOrderService.lambdaUpdate()
                .eq(WorkOrder::getLineId, id)
                .set(WorkOrder::getLineId, null)
                .update();
    }

    private ProductionLineVO buildVO(ProductionLine line, String workshopName) {
        ProductionLineVO vo = new ProductionLineVO();
        vo.setId(line.getId());
        vo.setName(line.getName());
        vo.setWorkshopId(line.getWorkshopId());
        vo.setCurrentProcessId(line.getCurrentProcessId());
        vo.setStatus(line.getStatus());
        vo.setWorkshopName(workshopName);
        if (line.getCreatedAt() != null) {
            vo.setCreatedAt(line.getCreatedAt().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        }

        List<Workstation> stations = workstationService.lambdaQuery()
                .eq(Workstation::getProductionLineId, line.getId())
                .eq(Workstation::getIsDeleted, 0)
                .list();
        vo.setStationCount(stations.size());

        Workstation lastStation = stations.stream()
                .max((a, b) -> {
                    String ca = a.getCode() != null ? a.getCode() : "";
                    String cb = b.getCode() != null ? b.getCode() : "";
                    return ca.compareTo(cb);
                })
                .orElse(null);
        int lastFinished = lastStation != null && lastStation.getFinishedCount() != null
                ? lastStation.getFinishedCount() : 0;
        int lastNg = lastStation != null && lastStation.getNgCount() != null
                ? lastStation.getNgCount() : 0;
        vo.setFinishedCount(lastFinished + lastNg);
        vo.setNgCount(lastNg);

        if (line.getCurrentWorkorderId() != null) {
            WorkOrder wo = workOrderService.lambdaQuery()
                    .eq(WorkOrder::getId, line.getCurrentWorkorderId())
                    .eq(WorkOrder::getIsDeleted, 0)
                    .one();
            if (wo != null) {
                vo.setWorkOrderCode(wo.getCode());
                vo.setPlanQty(wo.getPlanQty());
            }
        }

        return vo;
    }
}
