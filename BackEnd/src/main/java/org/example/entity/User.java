package org.example.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import java.io.Serializable;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.Setter;
import lombok.experimental.Accessors;

/**
 * <p>
 * 人员表
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
@Getter
@Setter
@Accessors(chain = true)
public class User implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 工号
     */
    private String employeeNo;

    /**
     * 姓名
     */
    private String name;

    /**
     * 角色：admin/leader/operator/inspector
     */
    private String role;

    /**
     * 所属班组ID（预留）
     */
    private Long teamId;

    /**
     * 所属车间ID
     */
    private Long workshopId;

    /**
     * 状态：在岗/离岗
     */
    private String status;

    /**
     * 头像URL
     */
    private String avatarUrl;

    /**
     * 密码哈希
     */
    private String passwordHash;

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
