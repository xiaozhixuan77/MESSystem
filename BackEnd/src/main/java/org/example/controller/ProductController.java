package org.example.controller;

import org.example.dto.response.R;
import org.example.entity.Process;
import org.example.entity.ProcessStep;
import org.example.entity.Product;
import org.example.service.ProcessService;
import org.example.service.ProcessStepService;
import org.example.service.ProductService;
import org.example.vo.ProcessStepVO;
import org.example.vo.ProcessWithStepsVO;
import org.example.vo.ProductVO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.stream.Collectors;

@RestController
public class ProductController {

    private final ProductService productService;
    private final ProcessService processService;
    private final ProcessStepService processStepService;

    public ProductController(ProductService productService,
                             ProcessService processService,
                             ProcessStepService processStepService) {
        this.productService = productService;
        this.processService = processService;
        this.processStepService = processStepService;
    }

    @GetMapping("/products")
    public R<List<ProductVO>> list(@RequestParam(required = false) String keyword) {
        var query = productService.lambdaQuery()
                .eq(Product::getIsDeleted, 0);
        if (keyword != null && !keyword.isBlank()) {
            query.and(w -> w.like(Product::getCode, keyword).or().like(Product::getName, keyword));
        }
        List<Product> products = query.list();
        List<ProductVO> vos = products.stream().map(p -> {
            ProductVO vo = new ProductVO();
            vo.setId(p.getId());
            vo.setCode(p.getCode());
            vo.setName(p.getName());
            vo.setDefaultProcessId(p.getDefaultProcessId());
            return vo;
        }).collect(Collectors.toList());
        return R.ok(vos);
    }

    @GetMapping("/products/{code}/process")
    public R<ProcessWithStepsVO> getProductProcess(@PathVariable String code) {
        Product product = productService.lambdaQuery()
                .eq(Product::getCode, code)
                .eq(Product::getIsDeleted, 0)
                .one();
        if (product == null) {
            return R.error(404, "产品不存在");
        }
        if (product.getDefaultProcessId() == null) {
            return R.error(400, "该产品未配置默认工艺");
        }

        Process process = processService.getById(product.getDefaultProcessId());
        if (process == null) {
            return R.error(404, "工艺不存在");
        }

        List<ProcessStep> steps = processStepService.lambdaQuery()
                .eq(ProcessStep::getProcessId, process.getId())
                .eq(ProcessStep::getIsDeleted, 0)
                .orderByAsc(ProcessStep::getSeqNo)
                .list();

        ProcessWithStepsVO vo = new ProcessWithStepsVO();
        vo.setId(process.getId());
        vo.setCode(process.getCode());
        vo.setName(process.getName());
        vo.setApplicableProductCodes(process.getApplicableProductCodes());
        vo.setSteps(steps.stream().map(s -> {
            ProcessStepVO stepVO = new ProcessStepVO();
            stepVO.setId(s.getId());
            stepVO.setSeqNo(s.getSeqNo());
            stepVO.setOpCode(s.getOpCode());
            stepVO.setName(s.getName());
            return stepVO;
        }).collect(Collectors.toList()));

        return R.ok(vo);
    }
}
