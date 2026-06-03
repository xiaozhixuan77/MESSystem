package org.example.service;

import org.example.entity.Workstation;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 工作站表 服务类
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
public interface WorkstationService extends IService<Workstation> {

    /**
     * 清零指定产线下所有工作站的计数器（已加工/原料/完工/NG）
     */
    void resetCounters(Long lineId);
}
