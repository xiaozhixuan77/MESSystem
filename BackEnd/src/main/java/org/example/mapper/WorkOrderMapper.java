package org.example.mapper;

import org.example.entity.WorkOrder;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface WorkOrderMapper extends BaseMapper<WorkOrder> {

    /** 查最大工单号（含已删除），避免逻辑删除导致号重复 */
    @Select("SELECT MAX(code) FROM work_order WHERE code LIKE 'MO%'")
    String selectMaxCode();
}
