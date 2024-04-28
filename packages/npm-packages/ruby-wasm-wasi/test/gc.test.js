import { initRubyVM } from "./init";
import { describe, test, expect } from "vitest"

describe("GC integration", () => {
  test("Wrapped Ruby object should live until wrapper will be released", async () => {
    const vm = await initRubyVM();
    const run = vm.eval(`
      require "js"
      proc do |imports|
        imports.call(:mark_js_object_live, JS::Object.wrap(Object.new))
      end
    `);
    const livingObjects = new Set();
    run.call(
      "call",
      vm.wrap({
        mark_js_object_live: (object) => {
          livingObjects.add(object);
        },
      }),
    );
    vm.eval("GC.start");
    for (const object of livingObjects) {
      // Ensure that all objects are still alive
      object.call("itself");
    }
  });

  test("protect exported Ruby objects", async () => {
    function dropRbValue(value) {
      if (value.inner.drop) {
        value.inner.drop();
      } else if (global.gc) {
        global.gc();
      } else {
        console.warn("--expose-gc is not enabled. Skip GC test.")
      }
    }
    const vm = await initRubyVM();
    const initialGCCount = Number(vm.eval("GC.count").toString());
    const robj = vm.eval("$x = Object.new");
    const robjId = robj.call("object_id").toString();
    expect(robjId).not.toEqual("");

    vm.eval("GC.start");
    expect(robj.call("object_id").toString()).toBe(robjId);
    expect(Number(vm.eval("GC.count").toString())).toEqual(initialGCCount + 1);

    const robj2 = vm.eval("$x");
    vm.eval("GC.start");
    expect(robj2.call("object_id").toString()).toBe(robjId);

    const robj3 = robj2.call("itself");
    vm.eval("GC.start");
    expect(robj3.call("object_id").toString()).toBe(robjId);

    dropRbValue(robj);
    expect(robj2.call("object_id").toString()).toBe(robjId);
    expect(robj3.call("object_id").toString()).toBe(robjId);

    vm.eval("GC.start");
    expect(robj2.call("object_id").toString()).toBe(robjId);
    expect(robj3.call("object_id").toString()).toBe(robjId);

    dropRbValue(robj2);
    dropRbValue(robj3);

    vm.eval("GC.start");
  });

  test("protect objects having same hash values from GC", async () => {
    const vm = await initRubyVM();
    vm.eval(`
    class X
      def hash
        42
      end
      def eql?(other)
        true
      end
    end
    `);

    const o1 = vm.eval(`X.new`);
    const o2 = vm.eval(`X.new`);
    const o3 = vm.eval(`X.new`);
    vm.eval(`GC.start`);
    expect(o1.call("hash").toString()).toBe(o2.call("hash").toString());
    expect(o2.call("hash").toString()).toBe(o3.call("hash").toString());
  });

  test("stop GC while having a sandwitched JS frame", async () => {
    const vm = await initRubyVM();
    const o = vm.eval(`
    require "js"

    JS.eval(<<~JS)
      return {
        takeVM(vm) {
          return vm.eval("GC.disable").toJS();
        }
      }
    JS
    `);
    const wasDisabled = o.call("takeVM", vm.wrap(vm));
    expect(wasDisabled.toJS()).toBe(true);
    // Ensure that GC is enabled back
    const isNotEnabledBack = vm.eval("GC.enable");
    expect(isNotEnabledBack.toJS()).toBe(false);

    // Re-start pending GC (including the incremental one)
    vm.eval("GC.start");

    // Disable GC before the nested call
    vm.eval("GC.disable");
    const o2 = vm.eval(`
    JS.eval(<<~JS)
      return {
        takeVM(vm) {
          return vm.eval("GC.disable").toJS();
        }
      }
    JS
    `);
    const wasDisabled2 = o2.call("takeVM", vm.wrap(vm));
    expect(wasDisabled2.toJS()).toBe(true);
    // Ensure that GC is still disabled because it was disabled before the nested call
    const isNotEnabledBack2 = vm.eval("GC.enable");
    expect(isNotEnabledBack2.toJS()).toBe(true);
  });
});
