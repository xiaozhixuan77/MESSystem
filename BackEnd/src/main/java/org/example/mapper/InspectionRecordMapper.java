package org.example.mapper;

import org.example.entity.InspectionRecord;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

/**
 * <p>
 * 抽检记录表 Mapper 接口
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
@Mapper
public interface InspectionRecordMapper extends BaseMapper<InspectionRecord> {

}
