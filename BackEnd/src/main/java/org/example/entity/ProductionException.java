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
 * 生产异常表
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
@Getter
@Setter
@Accessors(chain = true)
@TableName("production_exception")
public class ProductionException implements Serializable {

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
     * 产线ID
     */
    private Long lineId;

    /**
     * 工作站ID（整线异常时为空）
     */
    private Long stationId;

    /**
     * 上报人ID
     */
    private Long reporterId;

    /**
     * 上报时间
     */
    private LocalDateTime reportTime;

    /**
     * 异常描述
     */
    private String description;

    /**
     * 处理人ID
     */
    private Long handledBy;

    /**
     * 处理时间
     */
    private LocalDateTime handleTime;

    /**
     * 处理动作：恢复/关闭
     */
    private String handleAction;

    /**
     * 是否已解决：0-否，1-是
     */
    private Byte resolved;

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
