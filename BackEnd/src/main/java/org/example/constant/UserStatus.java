package org.example.constant;

import lombok.Getter;

@Getter
public enum UserStatus {

    ACTIVE("在岗"),
    OFFLINE("离岗");

    private final String label;

    UserStatus(String label) {
        this.label = label;
    }
}
