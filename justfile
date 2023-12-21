gen *args='':
    flutter pub get
    flutter_rust_bridge_codegen \
        --rust-input native/src/api.rs \
        --dart-output lib/bridge_generated.dart \
        --c-output ios/Runner/bridge_generated.h \
        --extra-c-output-path macos/Runner/ \
        --dart-decl-output lib/bridge_definitions.dart \
        --wasm {{args}}

clean:
    flutter clean
    cd native && cargo clean

run-on *args='':
    flutter run -d {{args}}

run-on-web *args='':
    dart run flutter_rust_bridge:serve {{args}}
