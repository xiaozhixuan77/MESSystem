package org.example.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.annotation.Version;
import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.Setter;
import lombok.experimental.Accessors;

/**
 * <p>
 * 工单表
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
@Getter
@Setter
@Accessors(chain = true)
@TableName("work_order")
public class WorkOrder implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 工单号
     */
    private String code;

    /**
     * 类型：试产/量产/返工
     */
    private String type;

    /**
     * 所属车间ID
     */
    private Long workshopId;

    /**
     * 产线ID
     */
    private Long lineId;

    /**
     * 产品ID
     */
    private Long productId;

    /**
     * 工艺ID
     */
    private Long processId;

    /**
     * 计划数量
     */
    private Integer planQty;

    /**
     * 计划开始时间
     */
    private LocalDateTime planStartTime;

    /**
     * 计划结束时间
     */
    private LocalDateTime planEndTime;

    /**
     * 状态：待派工/已派工/生产中/暂停中/生产完成/已报工/完工/报废
     */
    private String status;

    /**
     * 来源：Web创建/APP创建
     */
    private String source;

    /**
     * 操作员ID
     */
    private Long operatorId;

    /**
     * 派工时间
     */
    private LocalDateTime dispatchTime;

    /**
     * 实际开始时间
     */
    private LocalDateTime actualStartTime;

    /**
     * 实际结束时间
     */
    private LocalDateTime actualEndTime;

    /**
     * 暂停时间
     */
    private LocalDateTime pauseTime;

    /**
     * 申报良品数
     */
    private Integer reportedQtyGood;

    /**
     * 申报NG数
     */
    private Integer reportedQtyNg;

    /**
     * 申报工时
     */
    private BigDecimal reportedHours;

    /**
     * 异常说明
     */
    private String exceptionNote;

    /**
     * 创建人ID
     */
    private Long createdBy;

    /**
     * 源工单ID（返工关联）
     */
    private Long sourceWorkorderId;

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
    @Version
    private Integer version;

    /**
     * 逻辑删除：0-未删除，1-已删除
     */
    private Byte isDeleted;
}
