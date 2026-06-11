package org.example.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * 仿真器配置 — 读取 application.yml 中 simulator.* 配置项。
 */
@Configuration
@ConfigurationProperties(prefix = "simulator")
public class SimulatorConfig {

    /** Tick 间隔 (ms)，默认 1000 */
    private long tickInterval = 1000;

    /** 良品率，默认 0.95 */
    private double goodRate = 0.95;

    /** Tick 调度线程池大小，默认 16 */
    private int tickThreadPoolSize = 16;

    public long getTickInterval() {
        return tickInterval;
    }

    public void setTickInterval(long tickInterval) {
        this.tickInterval = tickInterval;
    }

    public double getGoodRate() {
        return goodRate;
    }

    public void setGoodRate(double goodRate) {
        this.goodRate = goodRate;
    }

    public int getTickThreadPoolSize() {
        return tickThreadPoolSize;
    }

    public void setTickThreadPoolSize(int tickThreadPoolSize) {
        this.tickThreadPoolSize = tickThreadPoolSize;
    }
}
