void hello() {
    int a = 0;
jump:
    ++a;
    if(a <= 10) {
        goto jump;
    }
}
