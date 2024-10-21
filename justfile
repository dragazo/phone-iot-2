gen *args='':
    flutter pub get
    flutter_rust_bridge_codegen generate

clean:
    flutter clean
    cd native && cargo clean

run-on *args='':
    flutter run -d {{args}}

run-on-web *args='':
    dart run flutter_rust_bridge:serve {{args}}
