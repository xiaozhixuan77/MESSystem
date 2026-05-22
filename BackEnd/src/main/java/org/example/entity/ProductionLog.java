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
 * 产线运行日志表
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
@Getter
@Setter
@Accessors(chain = true)
@TableName("production_log")
public class ProductionLog implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 产线ID
     */
    private Long lineId;

    /**
     * 工作站ID
     */
    private Long stationId;

    /**
     * 工单ID
     */
    private Long workOrderId;

    /**
     * 事件类型：启动/停止/复位/加工/出料/异常
     */
    private String eventType;

    /**
     * 产品序列号
     */
    private String productSn;

    /**
     * 事件时间
     */
    private LocalDateTime eventTime;

    /**
     * 扩展JSON数据
     */
    private String payload;

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
