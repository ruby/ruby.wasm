require "erb"

exts = ARGV

template = %q{
#define init(func, name) {	\
    extern void func(void);	\
    ruby_init_ext(name".so", func); \
}

void ruby_init_ext(const char *name, void (*init)(void));

void Init_extra_exts(void) {
<% exts.each do |ext| %>
  init(<%= "Init_#{ext}" %>, "<%= ext %>");
<% end %>
}
}

puts ERB.new(template).run
