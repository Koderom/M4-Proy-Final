package com.example.m4_proy_final;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
public class M4ProyFinalApplication {

	public static void main(String[] args) {
		SpringApplication.run(M4ProyFinalApplication.class, args);
	}

	@RestController
	class HelloController {
		@GetMapping("/")
		public String hello() {
			return "M4 Proy Final is running!";
		}
	}

	@RestController
	class HealthController {
		@GetMapping("/health")
		public String health() {
			return "Server Healthy!";
		}
	}

	@RestController
	class DateController {
		@GetMapping("/date")
		public String date() {
			return "Current Server Date: " + java.time.LocalDate.now();
		}
	}
}
