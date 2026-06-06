package org.example.e2e;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.dto.request.LoginRequest;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public abstract class E2ETestBase {

    @Autowired
    protected MockMvc mockMvc;

    @Autowired
    protected ObjectMapper objectMapper;

    protected String adminToken;
    protected String leaderToken;
    protected String operatorToken;
    protected String inspectorToken;

    @BeforeEach
    void setUpBase() throws Exception {
        // 预登录所有角色
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

    // ---- HTTP helpers ----

    protected MvcResult performGet(String url, String token) throws Exception {
        return mockMvc.perform(get(url)
                        .characterEncoding("UTF-8")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andReturn();
    }

    protected MvcResult performGetExpectAny(String url, String token) throws Exception {
        return mockMvc.perform(get(url)
                        .characterEncoding("UTF-8")
                        .header("Authorization", "Bearer " + token))
                .andReturn();
    }

    protected MvcResult performPost(String url, String token) throws Exception {
        return mockMvc.perform(post(url)
                        .characterEncoding("UTF-8")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andReturn();
    }

    protected MvcResult performPostWithBody(String url, Object body, String token) throws Exception {
        return mockMvc.perform(post(url)
                        .characterEncoding("UTF-8")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andReturn();
    }

    protected MvcResult performPostWithBodyExpectAny(String url, Object body, String token) throws Exception {
        return mockMvc.perform(post(url)
                        .characterEncoding("UTF-8")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andReturn();
    }

    protected MvcResult performPutWithBody(String url, Object body, String token) throws Exception {
        return mockMvc.perform(put(url)
                        .characterEncoding("UTF-8")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andReturn();
    }

    protected MvcResult performDelete(String url, String token) throws Exception {
        return mockMvc.perform(delete(url)
                        .characterEncoding("UTF-8")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andReturn();
    }

    // ---- Login ----

    protected String loginAndGetToken(String username, String password) throws Exception {
        LoginRequest req = new LoginRequest();
        req.setUsername(username);
        req.setPassword(password);
        MvcResult result = mockMvc.perform(post("/auth/login")
                        .characterEncoding("UTF-8")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString(StandardCharsets.UTF_8));
        return root.get("data").get("token").asText();
    }

    // ---- JSON parsing ----

    protected JsonNode parseJson(MvcResult result) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    protected JsonNode dataNode(MvcResult result) throws Exception {
        return parseJson(result).get("data");
    }

    protected int responseCode(MvcResult result) throws Exception {
        return parseJson(result).get("code").asInt();
    }

    protected String responseMessage(MvcResult result) throws Exception {
        return parseJson(result).get("message").asText();
    }

    // ---- Assertions ----

    protected void assertOk(MvcResult result) throws Exception {
        assertEquals(200, responseCode(result), "Expected 200 but got: " + result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    protected void assertError(MvcResult result, int expectedCode) throws Exception {
        assertEquals(expectedCode, responseCode(result),
                "Expected code " + expectedCode + " but got: " + result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    protected void assertErrorMessageContains(MvcResult result, int expectedCode, String keyword) throws Exception {
        assertError(result, expectedCode);
        String msg = responseMessage(result);
        assertTrue(msg != null && msg.contains(keyword),
                "Expected message containing '" + keyword + "' but got: " + msg);
    }

    protected void assertDataFieldEquals(MvcResult result, String field, Object expected) throws Exception {
        JsonNode data = dataNode(result);
        if (data == null || data.isNull()) {
            throw new AssertionError("data is null, expected field " + field + " = " + expected);
        }
        JsonNode fieldNode = data.get(field);
        String actual = fieldNode != null ? fieldNode.asText() : null;
        assertEquals(String.valueOf(expected), actual,
                "Field " + field + " mismatch: " + result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    protected Long extractDataId(MvcResult result) throws Exception {
        JsonNode data = dataNode(result);
        return data != null ? data.get("id").asLong() : null;
    }
}
