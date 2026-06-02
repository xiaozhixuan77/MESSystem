package org.example.controller;

import org.example.dto.response.R;
import org.example.entity.ProductionLine;
import org.example.service.ProductionLineService;
import org.example.vo.ProductionLineVO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.stream.Collectors;

@RestController
public class ProductionLineController {

    private final ProductionLineService productionLineService;

    public ProductionLineController(ProductionLineService productionLineService) {
        this.productionLineService = productionLineService;
    }

    @GetMapping("/lines")
    public R<List<ProductionLineVO>> list(@RequestParam(required = false) Long workshopId) {
        var query = productionLineService.lambdaQuery()
                .eq(ProductionLine::getIsDeleted, 0);
        if (workshopId != null) {
            query.eq(ProductionLine::getWorkshopId, workshopId);
        }
        List<ProductionLine> lines = query.list();
        List<ProductionLineVO> vos = lines.stream().map(line -> {
            ProductionLineVO vo = new ProductionLineVO();
            vo.setId(line.getId());
            vo.setName(line.getName());
            vo.setWorkshopId(line.getWorkshopId());
            return vo;
        }).collect(Collectors.toList());
        return R.ok(vos);
    }
}
