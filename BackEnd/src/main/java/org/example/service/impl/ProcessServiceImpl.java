package org.example.service.impl;

import org.example.entity.Process;
import org.example.mapper.ProcessMapper;
import org.example.service.ProcessService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 工艺表 服务实现类
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
@Service
public class ProcessServiceImpl extends ServiceImpl<ProcessMapper, Process> implements ProcessService {

}
