#include <iostream>
 
class Foo {
        public:
                Foo(int val): val_(val) {}
                int val_;
};
 
class Bar: public Foo {
        public:
                Bar(): Foo(42) {}
                int getter() { return Foo::val_; }
};
 
int main()
{
        Bar bar;
        std::cout << bar.getter() << std::endl;
        return 0;
}
