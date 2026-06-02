package org.example.service;

import org.example.dto.request.WorkOrderCreateRequest;
import org.example.dto.request.WorkOrderUpdateRequest;
import org.example.entity.WorkOrder;
import com.baomidou.mybatisplus.extension.service.IService;

import java.util.List;

public interface WorkOrderService extends IService<WorkOrder> {

    List<WorkOrder> listWorkOrders(String role, Long userId, Long workshopId,
                                   String status, String type, Long lineId);

    WorkOrder createWorkOrder(WorkOrderCreateRequest request, Long createdBy);

    WorkOrder copyWorkOrder(Long sourceId, WorkOrderCreateRequest override, Long createdBy);

    WorkOrder updateWorkOrder(Long id, WorkOrderUpdateRequest request);

    WorkOrder getWorkOrderDetail(Long id);
}
