package com.example.ci_cd.hello;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {
    @GetMapping("")
    public ResponseEntity hello() {
        // test
        return ResponseEntity.ok().body("hello");
    }
}
