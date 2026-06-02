package org.example.controller;

import org.example.dto.response.R;
import org.example.entity.Workshop;
import org.example.service.WorkshopService;
import org.example.vo.WorkshopVO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.stream.Collectors;

@RestController
public class WorkshopController {

    private final WorkshopService workshopService;

    public WorkshopController(WorkshopService workshopService) {
        this.workshopService = workshopService;
    }

    @GetMapping("/workshops")
    public R<List<WorkshopVO>> list() {
        List<Workshop> workshops = workshopService.lambdaQuery()
                .eq(Workshop::getIsDeleted, 0)
                .list();
        List<WorkshopVO> vos = workshops.stream().map(w -> {
            WorkshopVO vo = new WorkshopVO();
            vo.setId(w.getId());
            vo.setName(w.getName());
            return vo;
        }).collect(Collectors.toList());
        return R.ok(vos);
    }
}
