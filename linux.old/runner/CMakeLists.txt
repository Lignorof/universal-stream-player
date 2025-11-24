# The name of the executable.
set(BINARY_NAME "universal_stream_player")
# The name of the project.
set(PROJECT_NAME "universal_stream_player")

# Add the executable.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "utils.cc"
  "${FLUTTER_MANAGED_DIR}/generated_config.cc"
)

# Add the standard Flutter settings.
apply_standard_settings(${BINARY_NAME})

# Add the compile definitions for the Flutter project name.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_PROJECT_NAME=\"${PROJECT_NAME}\"")

# --- Adição para flutter_web_auth_2 ---
# Define o esquema de URL para o pacote de autenticação web no Linux.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_WEB_AUTH_2_URL_SCHEME=http" )

# Link the executable to Flutter and the plugin libraries.
target_link_libraries(${BINARY_NAME}
  PRIVATE
  flutter
  flutter_wrapper_app
)

# Add the GTK dependency.
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)
