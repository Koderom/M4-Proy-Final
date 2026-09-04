package com.example.m4_proy_final;

import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.mockStatic;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class M4ProyFinalApplicationTests {
	@Autowired
	private MockMvc mockMvc;

	@Test
	void contextLoads() {
	}

	@Test
	void main_shouldStartSpringApplication() {
		String[] args = {};

		try (MockedStatic<SpringApplication> mocked = mockStatic(SpringApplication.class)) {

			M4ProyFinalApplication.main(args);

			mocked.verify(() ->
					SpringApplication.run(M4ProyFinalApplication.class, args)
			);
		}
	}

	@Test
	void checkRootResponse() throws Exception {
		mockMvc.perform(get("/")
						.accept(MediaType.TEXT_PLAIN))
				.andExpect(status().isOk())
				.andExpect(content().string("M4 Proy Final is running!"));
	}

	@Test
	void checkHealthyResponse() throws Exception {
		mockMvc.perform(get("/health")
						.accept(MediaType.TEXT_PLAIN))
				.andExpect(status().isOk())
				.andExpect(content().string("Server Healthy!"));
	}

	@Test
	void checkDateResponse() throws Exception {
		mockMvc.perform(get("/date")
						.accept(MediaType.TEXT_PLAIN))
				.andExpect(status().isOk())
				.andExpect(content().string("Current Server Date: " + java.time.LocalDate.now()));
	}
}
