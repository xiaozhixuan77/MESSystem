package org.example.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.example.entity.LineProcessSupport;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;

@Mapper
public interface LineProcessSupportMapper extends BaseMapper<LineProcessSupport> {

    /** 绕过逻辑删除查询，查找包含已删除的关联记录 */
    @Select("SELECT * FROM line_process_support WHERE line_id = #{lineId} AND process_id = #{processId}")
    LineProcessSupport findAnyByLineIdAndProcessId(@Param("lineId") Long lineId, @Param("processId") Long processId);
}
