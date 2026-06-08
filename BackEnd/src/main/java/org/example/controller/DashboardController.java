package org.example.controller;

import org.example.dto.response.R;
import org.example.security.RequiresPermission;
import org.example.service.DashboardService;
import org.example.vo.DashboardVO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DashboardController {

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping("/dashboard")
    @RequiresPermission("dashboard.view")
    public R<DashboardVO> dashboard(@RequestParam(defaultValue = "today") String scope) {
        if (!"today".equals(scope) && !"month".equals(scope)) {
            return R.error(400, "scope 只能为 today 或 month");
        }
        return R.ok(dashboardService.getDashboard(scope));
    }
}
