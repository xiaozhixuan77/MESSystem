package org.example.controller;

import org.example.dto.response.R;
import org.example.service.HomeService;
import org.example.vo.HomeSummaryVO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HomeController {

    private final HomeService homeService;

    public HomeController(HomeService homeService) {
        this.homeService = homeService;
    }

    @GetMapping("/home/summary")
    public R<HomeSummaryVO> summary() {
        return R.ok(homeService.getSummary());
    }
}
