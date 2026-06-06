package org.example.e2e;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.converter.MappingJackson2MessageConverter;
import org.springframework.messaging.simp.stomp.StompHeaders;
import org.springframework.messaging.simp.stomp.StompSession;
import org.springframework.messaging.simp.stomp.StompSessionHandlerAdapter;
import org.springframework.messaging.simp.stomp.StompFrameHandler;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.web.socket.WebSocketHttpHeaders;
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.messaging.WebSocketStompClient;

import java.lang.reflect.Type;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
public abstract class SNCTestBase {

    @DynamicPropertySource
    static void overrideDbName(DynamicPropertyRegistry registry) {
        String dbName = "snc_" + UUID.randomUUID().toString().replace("-", "").substring(0, 10);
        registry.add("spring.datasource.url", () ->
                "jdbc:h2:mem:" + dbName + ";MODE=MySQL;DATABASE_TO_UPPER=false;NON_KEYWORDS=USER,ROLE");
    }

    @LocalServerPort
    protected int port;

    @Autowired
    protected TestRestTemplate restTemplate;

    @Autowired
    protected ObjectMapper objectMapper;

    protected String adminToken;
    protected String leaderToken;
    protected String operatorToken;
    protected String inspectorToken;

    @BeforeEach
    void setUpBase() {
        adminToken = loginAndGetToken("ADMIN001", "123456");
        leaderToken = loginAndGetToken("LEADER001", "123456");
        operatorToken = loginAndGetToken("OP001", "123456");
        inspectorToken = loginAndGetToken("INS001", "123456");
    }

    protected String tokenFor(String role) {
        return switch (role) {
            case "admin" -> adminToken;
            case "leader" -> leaderToken;
            case "operator" -> operatorToken;
            case "inspector" -> inspectorToken;
            default -> throw new IllegalArgumentException("Unknown role: " + role);
        };
    }

    // ---- URL ----

    protected String baseUrl() {
        return "http://localhost:" + port;
    }

    // ---- HTTP helpers ----

    protected <T> ResponseEntity<Map> httpGet(String path, String token) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        return restTemplate.exchange(baseUrl() + path, HttpMethod.GET,
                new HttpEntity<>(headers), Map.class);
    }

    protected <T> ResponseEntity<Map> httpPost(String path, T body, String token) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        headers.setContentType(MediaType.APPLICATION_JSON);
        return restTemplate.exchange(baseUrl() + path, HttpMethod.POST,
                new HttpEntity<>(body, headers), Map.class);
    }

    protected ResponseEntity<Map> httpPostVoid(String path, String token) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        return restTemplate.exchange(baseUrl() + path, HttpMethod.POST,
                new HttpEntity<>(headers), Map.class);
    }

    protected <T> ResponseEntity<Map> httpPut(String path, T body, String token) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        headers.setContentType(MediaType.APPLICATION_JSON);
        return restTemplate.exchange(baseUrl() + path, HttpMethod.PUT,
                new HttpEntity<>(body, headers), Map.class);
    }

    protected ResponseEntity<Map> httpDelete(String path, String token) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        return restTemplate.exchange(baseUrl() + path, HttpMethod.DELETE,
                new HttpEntity<>(headers), Map.class);
    }

    // ---- Login ----

    protected String loginAndGetToken(String username, String password) {
        Map<String, String> body = Map.of("username", username, "password", password);
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, String>> entity = new HttpEntity<>(body, headers);
        ResponseEntity<Map> resp = restTemplate.exchange(
                baseUrl() + "/auth/login", HttpMethod.POST, entity, Map.class);
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) resp.getBody().get("data");
        return (String) data.get("token");
    }

    // ---- STOMP WebSocket helpers ----

    protected WebSocketStompClient createStompClient() {
        StandardWebSocketClient wsClient = new StandardWebSocketClient();
        WebSocketStompClient stompClient = new WebSocketStompClient(wsClient);
        MappingJackson2MessageConverter converter = new MappingJackson2MessageConverter();
        converter.setObjectMapper(objectMapper);
        stompClient.setMessageConverter(converter);
        return stompClient;
    }

    protected StompSession connectStomp(WebSocketStompClient client, String token) throws Exception {
        StompHeaders connectHeaders = new StompHeaders();
        connectHeaders.add("Authorization", "Bearer " + token);
        connectHeaders.setHeartbeat(new long[]{0, 0});

        return client.connectAsync(
                "ws://localhost:" + port + "/ws",
                new WebSocketHttpHeaders(),
                connectHeaders,
                new StompSessionHandlerAdapter() {})
                .get(10, TimeUnit.SECONDS);
    }

    protected BlockingQueue<Map<String, Object>> subscribeAndCollect(
            StompSession session, String topic) {
        BlockingQueue<Map<String, Object>> messages = new LinkedBlockingQueue<>();
        session.subscribe(topic, new StompFrameHandler() {
            @Override
            public Type getPayloadType(StompHeaders headers) {
                return Map.class;
            }

            @Override
            @SuppressWarnings("unchecked")
            public void handleFrame(StompHeaders headers, Object payload) {
                messages.add((Map<String, Object>) payload);
            }
        });
        return messages;
    }

    // ---- Assertions ----

    protected void assertHttpOk(ResponseEntity<Map> response) {
        assertEquals(HttpStatus.OK, response.getStatusCode(),
                "Expected 200 but got " + response.getStatusCode() + ": " + response.getBody());
    }

    protected void assertHttpError(ResponseEntity<Map> response, int expectedCode) {
        assertEquals(HttpStatus.valueOf(expectedCode), response.getStatusCode(),
                "Expected " + expectedCode + " but got " + response.getStatusCode() + ": " + response.getBody());
    }

    @SuppressWarnings("unchecked")
    protected Map<String, Object> dataMap(ResponseEntity<Map> response) {
        return (Map<String, Object>) response.getBody().get("data");
    }

    @SuppressWarnings("unchecked")
    protected Map<String, Object> dataMap(ResponseEntity<Map> response, String key) {
        Map<String, Object> data = dataMap(response);
        return (Map<String, Object>) data.get(key);
    }

    protected Long extractId(ResponseEntity<Map> response) {
        Object id = dataMap(response).get("id");
        return id instanceof Integer ? ((Integer) id).longValue() : (Long) id;
    }

    protected String extractField(ResponseEntity<Map> response, String field) {
        Object value = dataMap(response).get(field);
        return value != null ? value.toString() : null;
    }
}
