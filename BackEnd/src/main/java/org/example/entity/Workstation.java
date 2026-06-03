package org.example.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.annotation.Version;
import java.io.Serializable;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.Setter;
import lombok.experimental.Accessors;

/**
 * <p>
 * 工作站表
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
@Getter
@Setter
@Accessors(chain = true)
@TableName("workstation")
public class Workstation implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 工作站编码
     */
    private String code;

    /**
     * 工作站名称
     */
    private String name;

    /**
     * 所属产线ID
     */
    private Long productionLineId;

    /**
     * 设备编码
     */
    private String equipmentCode;

    /**
     * 当前工艺ID
     */
    private Long currentProcessId;

    /**
     * 设备状态：运行中/待机/故障
     */
    private String deviceStatus;

    /**
     * 工作状态：机械臂上料/出料等待/工作台固定...
     */
    private String workStatus;

    /**
     * 传送带状态：正转/反转/停
     */
    private String conveyorStatus;

    /**
     * 已加工件数
     */
    private Integer processedCount;

    /**
     * 原料数
     */
    private Integer rawCount;

    /**
     * 完工数
     */
    private Integer finishedCount;

    /**
     * NG数
     */
    private Integer ngCount;

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
