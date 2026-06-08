package org.example.service;

import org.example.dto.request.InspectionCreateRequest;
import org.example.entity.InspectionRecord;
import com.baomidou.mybatisplus.extension.service.IService;

public interface InspectionRecordService extends IService<InspectionRecord> {

    InspectionRecord inspect(InspectionCreateRequest request, Long inspectorId);
}
