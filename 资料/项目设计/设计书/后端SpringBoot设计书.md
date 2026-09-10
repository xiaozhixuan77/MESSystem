# 后端 Spring Boot 设计书

## 1. 概述

本文档定义工业管理 APP 后端服务的技术架构、模块划分、核心业务流程与实现方案。

**技术栈**：Spring Boot + MyBatis-Plus + MySQL + Redis + WebSocket(STOMP)
**JDK 版本**：17
**构建工具**：Maven
**关联文档**：[后端需求分析](../需求分析/后端需求分析.md)、[后端接口设计](../接口设计/后端接口设计.md)、[后端MySQL设计书](../数据库设计/后端MySQL设计书.md)、[前端Harmony设计书](前端Harmony设计书.md)

## 2. 工程架构

### 2.1 项目结构

```
MES/BackEnd/
├── src/main/java/org/example/
│   ├── MESApplication.java              # 启动类
│   ├── config/                          # 配置类
│   │   ├── SecurityConfig.java          # 安全/JWT 配置
│   │   ├── WebSocketConfig.java         # WebSocket/STOMP 配置
│   │   ├── MybatisPlusConfig.java       # MyBatis-Plus 配置
│   │   ├── RedisConfig.java             # Redis 配置
│   │   └── SchedulerConfig.java         # 定时任务配置
│   ├── controller/                      # 控制器层
│   │   ├── AuthController.java
│   │   ├── UserController.java
│   │   ├── WorkshopController.java
│   │   ├── ProductionLineController.java
│   │   ├── WorkstationController.java
│   │   ├── ProcessController.java
│   │   ├── ProductController.java
│   │   ├── WorkOrderController.java
│   │   ├── ExceptionController.java
│   │   ├── InspectionController.java
│   │   └── DashboardController.java
│   ├── service/                         # 业务层
│   │   ├── AuthService.java
│   │   ├── UserService.java
│   │   ├── WorkshopService.java
│   │   ├── ProductionLineService.java
│   │   ├── WorkstationService.java
│   │   ├── ProcessService.java
│   │   ├── ProductService.java
│   │   ├── WorkOrderService.java
│   │   ├── LineSimulatorService.java    # 产线仿真器（核心）
│   │   ├── ExceptionService.java
│   │   ├── InspectionService.java
│   │   └── DashboardService.java
│   ├── mapper/                          # 数据访问层
│   ├── entity/                          # 实体类
│   ├── dto/                             # 数据传输对象
│   │   ├── request/                     # 请求 DTO
│   │   └── response/                    # 响应 DTO
│   ├── vo/                              # 视图对象
│   ├── enums/                           # 枚举
│   │   ├── RoleEnum.java
│   │   ├── WorkOrderStatusEnum.java
│   │   ├── LineStatusEnum.java
│   │   └── DeviceStatusEnum.java
│   ├── exception/                       # 异常处理
│   │   ├── BusinessException.java
│   │   └── GlobalExceptionHandler.java
│   ├── websocket/                       # WebSocket 相关
│   │   ├── WebSocketController.java     # STOMP @MessageMapping 处理（客户端→服务端）
│   │   ├── WebSocketEventListener.java  # 连接/断开事件监听
│   │   └── LineBroadcaster.java         # 产线状态广播器
│   ├── simulator/                       # 产线仿真器
│   │   ├── LineSimulator.java           # 单产线仿真任务
│   │   ├── StationTickTask.java         # 工作站 Tick 任务
│   │   └── SimulatorManager.java        # 仿真器管理器（启动/停止/调度）
│   ├── security/                        # 安全相关
│   │   ├── JwtTokenProvider.java
│   │   ├── JwtAuthenticationFilter.java
│   │   └── PermissionAnnotation.java    # @RequiresPermission
│   ├── aspect/                          # AOP 切面
│   │   └── PermissionAspect.java        # 权限校验切面
│   └── util/                            # 工具类
│       ├── SnowflakeIdUtil.java         # 分布式 ID
│       └── DateUtil.java
├── src/main/resources/
│   ├── application.yml                  # 主配置
│   ├── application-dev.yml              # 开发环境
│   ├── application-prod.yml             # 生产环境
│   └── db/
│       └── init.sql                     # 数据库初始化脚本
└── pom.xml
```

### 2.2 Maven 依赖

```xml
<dependencies>
    <!-- Spring Boot Starter -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    
    <!-- WebSocket -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-websocket</artifactId>
    </dependency>
    
    <!-- Security + JWT -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-api</artifactId>
        <version>0.12.3</version>
    </dependency>
    
    <!-- MyBatis-Plus -->
    <dependency>
        <groupId>com.baomidou</groupId>
        <artifactId>mybatis-plus-spring-boot3-starter</artifactId>
        <version>3.5.5</version>
    </dependency>
    
    <!-- MySQL -->
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
        <scope>runtime</scope>
    </dependency>
    
    <!-- Redis -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis</artifactId>
    </dependency>
    
    <!-- MQTT（预留） -->
    <dependency>
        <groupId>org.springframework.integration</groupId>
        <artifactId>spring-integration-mqtt</artifactId>
    </dependency>
    
    <!-- Lombok -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    
    <!-- Validation -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
</dependencies>
```

## 3. 核心模块设计

### 3.1 RBAC 权限系统

#### 3.1.1 权限注解

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface RequiresPermission {
    String value();
}
```

#### 3.1.2 权限校验切面

```java
@Aspect
@Component
public class PermissionAspect {
    
    @Autowired
    private UserService userService;
    
    @Around("@annotation(requiresPermission)")
    public Object checkPermission(ProceedingJoinPoint point, RequiresPermission requiresPermission) throws Throwable {
        String permission = requiresPermission.value();
        Long userId = SecurityContextHolder.getCurrentUserId();
        
        Set<String> permissions = userService.getUserPermissions(userId);
        // 拥有 '*' 通配符的角色（如 admin）拥有全部权限
        if (!permissions.contains(permission) && !permissions.contains("*")) {
            throw new BusinessException(403, "无权限执行此操作: " + permission);
        }
        return point.proceed();
    }
}
```

#### 3.1.3 角色权限数据模型

```java
@TableName("role_permission")
public class RolePermission implements Serializable {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String role;        // admin/leader/operator/inspector
    private String permission;  // workorder.dispatch, line.start 等
}
```

### 3.2 JWT 认证

```java
@Component
public class JwtTokenProvider {
    @Value("${jwt.secret}")
    private String secretKey;

    @Value("${jwt.expiration:86400000}")
    private long validityInMs; // 默认 24h
    
    public String createToken(Long userId, String role) {
        Claims claims = Jwts.claims().subject(userId.toString()).build();
        claims.put("role", role);
        
        Date now = new Date();
        Date validity = new Date(now.getTime() + validityInMs);
        
        return Jwts.builder()
            .claims(claims)
            .issuedAt(now)
            .expiration(validity)
            .signWith(Keys.hmacShaKeyFor(secretKey.getBytes()))
            .compact();
    }
    
    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                .verifyWith(Keys.hmacShaKeyFor(secretKey.getBytes()))
                .build()
                .parseSignedClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }
    
    public String refreshToken(String token) {
        if (!validateToken(token)) {
            throw new BusinessException(401, "Token 已过期或无效");
        }
        Long userId = getUserId(token);
        String role = getRole(token);
        return createToken(userId, role);
    }
    
    public Long getUserId(String token) {
        Claims claims = Jwts.parser()
            .verifyWith(Keys.hmacShaKeyFor(secretKey.getBytes()))
            .build()
            .parseSignedClaims(token)
            .getPayload();
        return Long.valueOf(claims.getSubject());
    }
    
    public String getRole(String token) {
        Claims claims = Jwts.parser()
            .verifyWith(Keys.hmacShaKeyFor(secretKey.getBytes()))
            .build()
            .parseSignedClaims(token)
            .getPayload();
        return claims.get("role", String.class);
    }
}
```

### 3.3 工单状态机

```java
@Service
public class WorkOrderService {
    
    @Autowired
    private WorkOrderMapper workOrderMapper;
    @Autowired
    private ProductionLineService productionLineService;
    @Autowired
    private LineSimulatorService lineSimulatorService;
    @Autowired
    private LineBroadcaster broadcaster;
    
    /**
     * 检查操作员是否已有激活中的工单（生产中或暂停中）。
     * 派工前校验，避免同一操作员同时处理多个工单。
     */
    private boolean hasActiveWorkOrder(Long operatorId) {
        List<WorkOrder> activeList = workOrderMapper.selectList(
            new LambdaQueryWrapper<WorkOrder>()
                .eq(WorkOrder::getOperatorId, operatorId)
                .in(WorkOrder::getStatus, "生产中", "暂停中")
        );
        return !activeList.isEmpty();
    }
    
    /**
     * 派工。
     * 使用 SELECT ... FOR UPDATE 行锁防止派工并发竞争
     * （两个班组长同时将同一工单派给不同操作员）。
     */
    @Transactional(rollbackFor = Exception.class)
    @RequiresPermission("workorder.dispatch")
    public void dispatch(Long workOrderId, Long operatorId) {
        WorkOrder wo = workOrderMapper.selectByIdForUpdate(workOrderId);
        
        // 状态校验
        if (!"待派工".equals(wo.getStatus())) {
            throw new BusinessException(400, "只允许在'待派工'状态进行派工");
        }
        
        // 校验操作员是否已有激活工单
        if (hasActiveWorkOrder(operatorId)) {
            throw new BusinessException(400, "该操作员已持有激活工单");
        }
        
        wo.setStatus("已派工");
        wo.setOperatorId(operatorId);
        wo.setDispatchTime(LocalDateTime.now());
        workOrderMapper.updateById(wo);
        
        // 广播给被指派操作员
        broadcaster.sendToUser(operatorId, "/queue/todos", "您有新的派工任务");
    }
    
    /**
     * 开工。需同时校验工单状态 + 操作员身份 + 产线空闲。
     * 使用行锁防止产线被两个工单同时占用。
     */
    @Transactional(rollbackFor = Exception.class)
    @RequiresPermission("workorder.start")
    public void start(Long workOrderId) {
        WorkOrder wo = workOrderMapper.selectByIdForUpdate(workOrderId);
        Long currentUserId = SecurityContextHolder.getCurrentUserId();
        
        if (!"已派工".equals(wo.getStatus())) {
            throw new BusinessException(400, "工单未派工");
        }
        if (!wo.getOperatorId().equals(currentUserId)) {
            throw new BusinessException(403, "只有被指派的操作员才能开工");
        }
        
        // 校验产线是否空闲（产线表也使用行锁防并发）
        ProductionLine line = productionLineService.getByIdForUpdate(wo.getLineId());
        if (!"空闲".equals(line.getStatus())) {
            throw new BusinessException(400, "产线不是空闲状态");
        }
        
        wo.setStatus("生产中");
        wo.setActualStartTime(LocalDateTime.now());
        workOrderMapper.updateById(wo);
        
        // 启动产线仿真
        lineSimulatorService.startSimulation(wo.getLineId(), workOrderId);
        
        // 广播状态变更
        broadcaster.broadcastWorkOrderUpdate(workOrderId);
    }
    
    @Transactional(rollbackFor = Exception.class)
    @RequiresPermission("workorder.report")
    public void report(Long workOrderId, ReportRequest req) {
        WorkOrder wo = workOrderMapper.selectByIdForUpdate(workOrderId);
        
        if (!"生产完成".equals(wo.getStatus())) {
            throw new BusinessException(400, "只有'生产完成'状态才能报工");
        }
        if (req.getGood() + req.getNg() > wo.getPlanQty()) {
            throw new BusinessException(400, "良品+NG不能超过计划数量");
        }
        
        wo.setStatus("已报工");
        wo.setReportedQtyGood(req.getGood());
        wo.setReportedQtyNg(req.getNg());
        wo.setReportedHours(req.getHours());
        wo.setExceptionNote(req.getNote());
        workOrderMapper.updateById(wo);
        
        // 广播给质检员
        broadcaster.broadcastInspectionUpdate(workOrderId);
    }
    
    // ... 其他状态转换方法（pause, resume, confirm, scrap 同理使用 selectByIdForUpdate + 状态校验）
}
```

### 3.4 产线仿真器

```java
@Service
public class LineSimulatorService {
    
    @Autowired
    private SimulatorManager simulatorManager;
    @Autowired
    private ProductionLogMapper logMapper;
    @Autowired
    private LineBroadcaster broadcaster;

    @Value("${simulator.good-rate:0.95}")
    private double goodRate;
    
    // 共享线程池，避免反复创建导致线程泄漏
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(
        Runtime.getRuntime().availableProcessors()
    );
    
    // 记录 future + executor 便于正确清理
    private final ConcurrentHashMap<Long, ScheduledFuture<?>> runningSimulators = new ConcurrentHashMap<>();
    
    public void startSimulation(Long lineId, Long workOrderId) {
        // 幂等校验
        if (runningSimulators.containsKey(lineId)) {
            throw new BusinessException(400, "该产线已在仿真中");
        }
        
        LineSimulator simulator = new LineSimulator(lineId, workOrderId, goodRate);
        
        ScheduledFuture<?> future = scheduler.scheduleAtFixedRate(
            () -> tick(lineId, simulator), 0, 1, TimeUnit.SECONDS
        );
        
        runningSimulators.put(lineId, future);
        
        // 更新产线状态
        lineService.updateStatus(lineId, "生产中");
    }
    
    public void stopSimulation(Long lineId) {
        ScheduledFuture<?> future = runningSimulators.remove(lineId);
        if (future != null) {
            future.cancel(false);
        }
        lineService.updateStatus(lineId, "暂停中");
    }
    
    public void resetSimulation(Long lineId) {
        stopSimulation(lineId);
        stationService.resetCounters(lineId);
        lineService.updateStatus(lineId, "空闲");
    }
    
    private void tick(Long lineId, LineSimulator simulator) {
        try {
            // 推进每个工作站
            List<StationState> newStates = simulator.tick();
            
            // 写入日志
            ProductionLog log = new ProductionLog();
            log.setLineId(lineId);
            log.setEventType("加工");
            log.setEventTime(LocalDateTime.now());
            log.setPayload(JSON.toJSONString(newStates));
            logMapper.insert(log);
            
            // 广播状态
            broadcaster.broadcastStationUpdate(lineId, newStates);
            
        } catch (Exception e) {
            log.error("仿真 tick 异常, lineId={}", lineId, e);
        }
    }
}
```

#### 3.4.1 单产线仿真任务

```java
public class LineSimulator {
    private Long lineId;
    private Long workOrderId;
    private List<Workstation> stations;
    private Process process;
    private double goodRate;
    private int currentOpIndex = 0;
    
    public LineSimulator(Long lineId, Long workOrderId, double goodRate) {
        this.lineId = lineId;
        this.workOrderId = workOrderId;
        this.goodRate = goodRate;
        // 加载产线配置、工艺、工作站
        initialize();
    }
    
    public List<StationState> tick() {
        List<StationState> states = new ArrayList<>();
        
        // 按工艺顺序推进
        for (int i = 0; i < stations.size(); i++) {
            Workstation ws = stations.get(i);
            
            // 模拟加工逻辑
            if (ws.getDeviceStatus().equals("运行中")) {
                ws.setProcessedCount(ws.getProcessedCount() + 1);
                ws.setRawCount(ws.getRawCount() + 1);
                
                // 按配置良品率（simulator.good-rate）模拟
                if (Math.random() <= goodRate) {
                    ws.setFinishedCount(ws.getFinishedCount() + 1);
                } else {
                    ws.setNgCount(ws.getNgCount() + 1);
                }
            }
            
            states.add(new StationState(ws));
        }
        
        return states;
    }
}
```

### 3.5 WebSocket 广播

```java
@Service
public class LineBroadcaster {
    
    @Autowired
    private SimpMessagingTemplate messagingTemplate;
    @Autowired(required = false)  // 单实例部署时 Redis 可选
    private RedisTemplate<String, Object> redisTemplate;
    
    public void broadcastLineStatus(Long lineId, LineStatusVO status) {
        String topic = "/topic/lines/" + lineId;
        
        WebSocketMessage msg = WebSocketMessage.builder()
            .topic(topic)
            .version(System.currentTimeMillis())
            .eventId(generateEventId())
            .payload(status)
            .build();
        
        // 多实例部署时通过 Redis 发布，各实例的 RedisMessageListener 收到底转发本地 STOMP
        // 单实例时直接本地广播（避免不必要的 Redis 往返）
        if (redisTemplate != null) {
            redisTemplate.convertAndSend("ws:line:" + lineId, msg);
        } else {
            messagingTemplate.convertAndSend(topic, msg);
        }
    }
    
    public void broadcastStationUpdate(Long lineId, List<StationState> stations) {
        String topic = "/topic/lines/" + lineId + "/stations";
        
        WebSocketMessage msg = WebSocketMessage.builder()
            .topic(topic)
            .version(System.currentTimeMillis())
            .eventId(generateEventId())
            .payload(stations)
            .build();
        
        if (redisTemplate != null) {
            redisTemplate.convertAndSend("ws:station:" + lineId, msg);
        } else {
            messagingTemplate.convertAndSend(topic, msg);
        }
    }
    
    public void sendToUser(Long userId, String destination, Object payload) {
        messagingTemplate.convertAndSendToUser(
            userId.toString(), destination, payload
        );
    }
}
```

多实例部署时需额外配置 Redis 消息监听器，将 Redis 消息转发到本地 STOMP：

```java
@Component
public class WebSocketRedisListener implements MessageListener {
    
    @Autowired
    private SimpMessagingTemplate messagingTemplate;
    
    @Override
    public void onMessage(Message message, byte[] pattern) {
        WebSocketMessage msg = JSON.parseObject(message.getBody(), WebSocketMessage.class);
        messagingTemplate.convertAndSend(msg.getTopic(), msg);
    }
}
```

### 3.6 WebSocket 配置

```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {
    
    @Autowired
    private WebSocketAuthInterceptor webSocketAuthInterceptor;
    
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/queue");
        config.setApplicationDestinationPrefixes("/app");
        config.setUserDestinationPrefix("/user");
    }
    
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // 原生 WebSocket 端点（HarmonyOS 前端使用）
        registry.addEndpoint("/ws")
            .setAllowedOriginPatterns("*");
        // SockJS 回退端点（Web 前端可选）
        registry.addEndpoint("/ws")
            .setAllowedOriginPatterns("*")
            .withSockJS();
    }
    
    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(webSocketAuthInterceptor);
    }
}
```

### 3.7 WebSocket 鉴权

```java
// StompUserPrincipal：包装 userId 为 Principal，供 STOMP 消息路由使用
public class StompUserPrincipal implements Principal {
    private final Long userId;
    
    public StompUserPrincipal(Long userId) {
        this.userId = userId;
    }
    
    @Override
    public String getName() {
        return userId.toString();
    }
    
    public Long getUserId() {
        return userId;
    }
}
```

```java
@Component
public class WebSocketAuthInterceptor implements ChannelInterceptor {
    
    @Autowired
    private JwtTokenProvider jwtTokenProvider;
    
    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        
        if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {
            String token = accessor.getFirstNativeHeader("Authorization");
            if (token != null && token.startsWith("Bearer ")) {
                token = token.substring(7);
                if (jwtTokenProvider.validateToken(token)) {
                    Long userId = jwtTokenProvider.getUserId(token);
                    accessor.setUser(new StompUserPrincipal(userId));
                } else {
                    throw new BusinessException(401, "WebSocket Token 无效");
                }
            } else {
                throw new BusinessException(401, "WebSocket 连接缺少 Authorization 头");
            }
        }
        return message;
    }
}
```

## 4. 统一响应格式

```java
@Data
public class R<T> {
    private int code;
    private String message;
    private T data;
    private long timestamp;
    
    public static <T> R<T> ok(T data) {
        R<T> r = new R<>();
        r.setCode(200);
        r.setMessage("success");
        r.setData(data);
        r.setTimestamp(System.currentTimeMillis());
        return r;
    }
    
    public static <T> R<T> error(int code, String message) {
        R<T> r = new R<>();
        r.setCode(code);
        r.setMessage(message);
        r.setTimestamp(System.currentTimeMillis());
        return r;
    }
}
```

## 5. 异常处理

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(BusinessException.class)
    public R<Void> handleBusinessException(BusinessException e) {
        return R.error(e.getCode(), e.getMessage());
    }
    
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public R<Void> handleValidationException(MethodArgumentNotValidException e) {
        String message = e.getBindingResult().getFieldErrors().stream()
            .map(error -> error.getField() + ": " + error.getDefaultMessage())
            .collect(Collectors.joining(", "));
        return R.error(400, message);
    }
    
    @ExceptionHandler(Exception.class)
    public R<Void> handleException(Exception e) {
        log.error("系统异常", e);
        return R.error(500, "系统内部错误");
    }
}
```

## 6. 数据库初始化

### 6.1 初始化脚本策略

使用 `src/main/resources/db/init.sql` 初始化数据：

```sql
-- 初始化管理员
INSERT INTO user (id, employee_no, name, role, status, password_hash) VALUES
(1, 'ADMIN001', '张建国', 'admin', '在岗', '$2a$10$...');

-- 初始化车间
INSERT INTO workshop (id, name) VALUES
(1, '机加工车间'),
(2, '柔性车间'),
(3, '智能组装车间'),
(4, 'SMT 车间');

-- 初始化产线
INSERT INTO production_line (id, name, workshop_id, status) VALUES
(1, '柔性组装线', 2, '空闲'),
(2, 'SMT 产线', 4, '空闲');

-- 初始化工作站
INSERT INTO workstation (id, code, name, production_line_id) VALUES
(1, 'WS-FLX-OP10', 'OP10 上料', 1),
(2, 'WS-FLX-OP20', 'OP20 主板组装', 1),
(3, 'WS-FLX-OP30', 'OP30 后盖组装', 1),
(4, 'WS-FLX-OP40', 'OP40 螺丝锁付', 1),
(5, 'WS-FLX-OP50', 'OP50 激光打标', 1),
(6, 'WS-FLX-OP60', 'OP60 成品检测', 1),
(7, 'WS-FLX-OP70', 'OP70 下料', 1);

-- 初始化角色权限
INSERT INTO role_permission (role, permission) VALUES
('admin', '*'),
('leader', 'workorder.view_team'),
('leader', 'workorder.create'),
('leader', 'workorder.dispatch'),
('leader', 'workorder.pause'),
('leader', 'workorder.resume'),
('leader', 'workorder.confirm'),
('leader', 'workorder.scrap'),
('leader', 'line.view'),
('leader', 'line.operate'),
('leader', 'station.operate'),
('leader', 'exception.view'),
('leader', 'exception.handle'),
('leader', 'dashboard.view'),
('operator', 'workorder.view_own'),
('operator', 'workorder.start'),
('operator', 'workorder.pause'),
('operator', 'workorder.resume'),
('operator', 'workorder.report'),
('operator', 'line.view'),
('operator', 'line.operate'),
('operator', 'station.operate'),
('operator', 'exception.report'),
('operator', 'dashboard.view'),
('inspector', 'inspection.create'),
('inspector', 'workorder.view_inspection'),
('inspector', 'line.view'),
('inspector', 'dashboard.view');
```

### 6.2 Flyway 迁移（可选）

如需版本化管理，可引入 Flyway：

```xml
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-mysql</artifactId>
</dependency>
```

## 7. 配置文件

### 7.1 application.yml

```yaml
spring:
  application:
    name: mes-system
  datasource:
    url: jdbc:mysql://localhost:3306/mes_db?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai
    username: root
    password: 123456
    driver-class-name: com.mysql.cj.jdbc.Driver
  data:
    redis:
      host: localhost
      port: 6379
      database: 0
  
server:
  port: 8080

mybatis-plus:
  configuration:
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl
  global-config:
    db-config:
      logic-delete-field: isDeleted
      logic-delete-value: 1
      logic-not-delete-value: 0

jwt:
  secret: your-256-bit-secret-key-here
  expiration: 86400000

simulator:
  tick-interval: 1000
  good-rate: 0.95
```

## 8. 启动类

```java
@SpringBootApplication
@EnableScheduling
@MapperScan("org.example.mapper")
public class MESApplication {
    public static void main(String[] args) {
        SpringApplication.run(MESApplication.class, args);
    }
}
```

## 9. Docker 部署

### 9.1 Dockerfile

```dockerfile
# 构建阶段
FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app

# 第一步：仅复制 pom.xml，下载依赖（利用 Docker 缓存层）
COPY pom.xml .
RUN apk add --no-cache maven && \
    mvn dependency:go-offline -B

# 第二步：复制源码并构建（源码变更时仅此层重建）
COPY src ./src
RUN mvn clean package -DskipTests

# 运行阶段
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080

ENV SPRING_PROFILES_ACTIVE=prod
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

### 9.2 docker-compose.yml

```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: mes-mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: 123456
      MYSQL_DATABASE: mes_db
      MYSQL_CHARSET: utf8mb4
      MYSQL_COLLATION: utf8mb4_unicode_ci
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - mes-network

  redis:
    image: redis:7-alpine
    container_name: mes-redis
    restart: always
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - mes-network

  backend:
    build:
      context: ./MES/BackEnd
      dockerfile: Dockerfile
    container_name: mes-backend
    restart: always
    depends_on:
      - mysql
      - redis
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/mes_db?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai
      SPRING_DATASOURCE_USERNAME: root
      SPRING_DATASOURCE_PASSWORD: 123456
      SPRING_DATA_REDIS_HOST: redis
      SPRING_DATA_REDIS_PORT: 6379
      JWT_SECRET: ${JWT_SECRET:-your-256-bit-secret-key-here}
    networks:
      - mes-network

volumes:
  mysql_data:
  redis_data:

networks:
  mes-network:
    driver: bridge
```

### 9.3 部署命令

```bash
# 1. 构建并启动全部服务
docker-compose up -d --build

# 2. 查看日志
docker-compose logs -f backend

# 3. 停止服务
docker-compose down

# 4. 停止并清除数据卷
docker-compose down -v
```

### 9.4 多环境配置

| 环境 | 启动方式 | 说明 |
|------|---------|------|
| 开发 | `docker-compose -f docker-compose.yml -f docker-compose.dev.yml up` | 挂载源码热更新 |
| 测试 | `docker-compose up -d` | 默认配置 |
| 生产 | `docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d` | Nginx 反向代理 + SSL |
