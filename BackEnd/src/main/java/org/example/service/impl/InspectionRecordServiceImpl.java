package org.example.service.impl;

import org.example.dto.request.InspectionCreateRequest;
import org.example.entity.InspectionRecord;
import org.example.entity.WorkOrder;
import org.example.exception.BusinessException;
import org.example.mapper.InspectionRecordMapper;
import org.example.service.InspectionRecordService;
import org.example.service.WorkOrderService;
import org.example.websocket.LineBroadcaster;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;

@Service
public class InspectionRecordServiceImpl
        extends ServiceImpl<InspectionRecordMapper, InspectionRecord>
        implements InspectionRecordService {

    private final WorkOrderService workOrderService;
    private final LineBroadcaster lineBroadcaster;

    public InspectionRecordServiceImpl(WorkOrderService workOrderService,
                                        LineBroadcaster lineBroadcaster) {
        this.workOrderService = workOrderService;
        this.lineBroadcaster = lineBroadcaster;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public InspectionRecord inspect(InspectionCreateRequest request, Long inspectorId) {
        WorkOrder wo = workOrderService.getById(request.getWorkOrderId());
        if (wo == null) {
            throw new BusinessException(404, "工单不存在");
        }

        if (!"已报工".equals(wo.getStatus())) {
            throw new BusinessException(400, "只能对已报工的工单进行抽检，当前状态: " + wo.getStatus());
        }

        int sampleGood = request.getSampleGood() != null ? request.getSampleGood() : 0;
        int sampleNg = request.getSampleNg() != null ? request.getSampleNg() : 0;
        int sampleQty = request.getSampleQty();

        if (sampleGood + sampleNg != sampleQty) {
            throw new BusinessException(400, "良品数+不良品数必须等于抽检数量");
        }

        int minQty = Math.max(1, (int) Math.ceil(wo.getPlanQty() * 0.05));
        int maxQty = Math.max(1, (int) Math.floor(wo.getPlanQty() * 0.10));
        if (sampleQty < minQty || sampleQty > maxQty) {
            throw new BusinessException(400,
                    "抽检数量必须在批次量的5%-10%之间（" + minQty + "-" + maxQty + "）");
        }

        InspectionRecord record = new InspectionRecord();
        record.setWorkOrderId(request.getWorkOrderId());
        record.setInspectorId(inspectorId);
        record.setInspectTime(LocalDateTime.now());
        record.setSampleQty(sampleQty);
        record.setSampleGood(sampleGood);
        record.setSampleNg(sampleNg);
        record.setDefectTypes(request.getDefectTypes());
        record.setDefectDescription(request.getDefectDescription());
        record.setConclusion(request.getConclusion());
        save(record);

        Map<String, Object> extra = Map.of(
                "inspectionId", record.getId(),
                "conclusion", record.getConclusion() != null ? record.getConclusion() : ""
        );
        lineBroadcaster.broadcastWorkOrderUpdate(wo.getLineId(), wo.getId(), wo.getCode(),
                "已报工", extra);

        return record;
    }
}
