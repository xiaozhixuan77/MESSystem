package org.example.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.io.Serializable;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.Setter;
import lombok.experimental.Accessors;

/**
 * <p>
 * 抽检记录表
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
@Getter
@Setter
@Accessors(chain = true)
@TableName("inspection_record")
public class InspectionRecord implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 关联工单ID
     */
    private Long workOrderId;

    /**
     * 质检员ID
     */
    private Long inspectorId;

    /**
     * 抽检时间
     */
    private LocalDateTime inspectTime;

    /**
     * 抽检数量
     */
    private Integer sampleQty;

    /**
     * 抽检良品数
     */
    private Integer sampleGood;

    /**
     * 抽检NG数
     */
    private Integer sampleNg;

    /**
     * 缺陷类型JSON：外观缺陷/尺寸偏差/功能失效/装配不良
     */
    private String defectTypes;

    /**
     * 不良描述
     */
    private String defectDescription;

    /**
     * 结论：通过/不通过
     */
    private String conclusion;

    /**
     * 创建时间
     */
    private LocalDateTime createdAt;

    /**
     * 更新时间
     */
    private LocalDateTime updatedAt;

    /**
     * 乐观锁版本号
     */
    private Integer version;

    /**
     * 逻辑删除：0-未删除，1-已删除
     */
    private Byte isDeleted;
}
