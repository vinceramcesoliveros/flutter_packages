// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/ast.dart';
import 'package:pigeon/kotlin_generator.dart';
import 'package:test/test.dart';

void main() {
  test('gen one class', () {
    final Class klass = Class(
      name: 'Foobar',
      fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'int',
            isNullable: true,
          ),
          name: 'field1',
        ),
      ],
    );
    final Root root = Root(
      apis: <Api>[],
      classes: <Class>[klass],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const KotlinOptions kotlinOptions = KotlinOptions();
    generateKotlin(kotlinOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('data class Foobar('));
    expect(code, contains('val field1: Long? = null'));
    expect(code, contains('fun fromMap(map: Map<String, Any?>): Foobar'));
    expect(code, contains('fun toMap(): Map<String, Any?>'));
  });

  test('gen one enum', () {
    final Enum anEnum = Enum(
      name: 'Foobar',
      members: <String>[
        'one',
        'two',
      ],
    );
    final Root root = Root(
      apis: <Api>[],
      classes: <Class>[],
      enums: <Enum>[anEnum],
    );
    final StringBuffer sink = StringBuffer();
    const KotlinOptions kotlinOptions = KotlinOptions();
    generateKotlin(kotlinOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('enum class Foobar(val raw: Int) {'));
    expect(code, contains('ONE(0)'));
    expect(code, contains('TWO(1)'));
  });

  test('primitive enum host', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Bar', location: ApiLocation.host, methods: <Method>[
        Method(
            name: 'bar',
            returnType: const TypeDeclaration.voidDeclaration(),
            arguments: <NamedType>[
              NamedType(
                  name: 'foo',
                  type:
                      const TypeDeclaration(baseName: 'Foo', isNullable: false))
            ])
      ])
    ], classes: <Class>[], enums: <Enum>[
      Enum(name: 'Foo', members: <String>['one', 'two'])
    ]);
    final StringBuffer sink = StringBuffer();
    const KotlinOptions kotlinOptions = KotlinOptions();
    generateKotlin(kotlinOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('enum class Foo(val raw: Int) {'));
    expect(code, contains('val fooArg = Foo.ofRaw(args[0] as Int)'));
  });

  test('gen one host api', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
              type: const TypeDeclaration(
                baseName: 'Input',
                isNullable: false,
              ),
              name: 'input',
            )
          ],
          returnType:
              const TypeDeclaration(baseName: 'Output', isNullable: false),
        )
      ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'String',
            isNullable: true,
          ),
          name: 'input',
        )
      ]),
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'String',
            isNullable: true,
          ),
          name: 'output',
        )
      ])
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    const KotlinOptions kotlinOptions = KotlinOptions();
    generateKotlin(kotlinOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('interface Api'));
    expect(code, contains('fun doSomething(input: Input): Output'));
    expect(code, contains('channel.setMessageHandler'));
  });

  test('all the simple datatypes header', () {
    final Root root = Root(apis: <Api>[], classes: <Class>[
      Class(name: 'Foobar', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'bool',
            isNullable: true,
          ),
          name: 'aBool',
        ),
        NamedType(
          type: const TypeDeclaration(
            baseName: 'int',
            isNullable: true,
          ),
          name: 'aInt',
        ),
        NamedType(
          type: const TypeDeclaration(
            baseName: 'double',
            isNullable: true,
          ),
          name: 'aDouble',
        ),
        NamedType(
          type: const TypeDeclaration(
            baseName: 'String',
            isNullable: true,
          ),
          name: 'aString',
        ),
        NamedType(
          type: const TypeDeclaration(
            baseName: 'Uint8List',
            isNullable: true,
          ),
          name: 'aUint8List',
        ),
        NamedType(
          type: const TypeDeclaration(
            baseName: 'Int32List',
            isNullable: true,
          ),
          name: 'aInt32List',
        ),
        NamedType(
          type: const TypeDeclaration(
            baseName: 'Int64List',
            isNullable: true,
          ),
          name: 'aInt64List',
        ),
        NamedType(
          type: const TypeDeclaration(
            baseName: 'Float64List',
            isNullable: true,
          ),
          name: 'aFloat64List',
        ),
      ]),
    ], enums: <Enum>[]);

    final StringBuffer sink = StringBuffer();

    const KotlinOptions kotlinOptions = KotlinOptions();
    generateKotlin(kotlinOptions, root, sink);
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('val aBool: Boolean? = null'));
    expect(code, contains('val aInt: Long? = null'));
    expect(code, contains('val aDouble: Double? = null'));
    expect(code, contains('val aString: String? = null'));
    expect(code, contains('val aUint8List: ByteArray? = null'));
    expect(code, contains('val aInt32List: IntArray? = null'));
    expect(code, contains('val aInt64List: LongArray? = null'));
    expect(code, contains('val aFloat64List: DoubleArray? = null'));
  });

  test('gen one flutter api', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
              type: const TypeDeclaration(
                baseName: 'Input',
                isNullable: false,
              ),
              name: '',
            )
          ],
          returnType:
              const TypeDeclaration(baseName: 'Output', isNullable: false),
        )
      ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'String',
            isNullable: true,
          ),
          name: 'input',
        )
      ]),
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'String',
            isNullable: true,
          ),
          name: 'output',
        )
      ])
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code,
        contains('class Api(private val binaryMessenger: BinaryMessenger)'));
    expect(code, matches('fun doSomething.*Input.*Output'));
  });

  test('gen host void api', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
              type: const TypeDeclaration(
                baseName: 'Input',
                isNullable: false,
              ),
              name: '',
            )
          ],
          returnType: const TypeDeclaration.voidDeclaration(),
        )
      ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'String',
            isNullable: true,
          ),
          name: 'input',
        )
      ]),
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, isNot(matches('.*doSomething(.*) ->')));
    expect(code, matches('doSomething(.*)'));
  });

  test('gen flutter void return api', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
              type: const TypeDeclaration(
                baseName: 'Input',
                isNullable: false,
              ),
              name: '',
            )
          ],
          returnType: const TypeDeclaration.voidDeclaration(),
        )
      ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'String',
            isNullable: true,
          ),
          name: 'input',
        )
      ]),
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('callback: () -> Unit'));
    expect(code, contains('callback()'));
  });

  test('gen host void argument api', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[],
          returnType:
              const TypeDeclaration(baseName: 'Output', isNullable: false),
        )
      ])
    ], classes: <Class>[
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'String',
            isNullable: true,
          ),
          name: 'output',
        )
      ]),
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('fun doSomething(): Output'));
    expect(code, contains('wrapped["result"] = api.doSomething()'));
    expect(code, contains('wrapped["error"] = wrapError(exception)'));
    expect(code, contains('reply(wrapped)'));
  });

  test('gen flutter void argument api', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[],
          returnType:
              const TypeDeclaration(baseName: 'Output', isNullable: false),
        )
      ])
    ], classes: <Class>[
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'String',
            isNullable: true,
          ),
          name: 'output',
        )
      ]),
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('fun doSomething(callback: (Output) -> Unit)'));
    expect(code, contains('channel.send(null)'));
  });

  test('gen list', () {
    final Root root = Root(apis: <Api>[], classes: <Class>[
      Class(name: 'Foobar', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'List',
            isNullable: true,
          ),
          name: 'field1',
        )
      ]),
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('data class Foobar'));
    expect(code, contains('val field1: List<Any?>? = null'));
  });

  test('gen map', () {
    final Root root = Root(apis: <Api>[], classes: <Class>[
      Class(name: 'Foobar', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'Map',
            isNullable: true,
          ),
          name: 'field1',
        )
      ]),
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('data class Foobar'));
    expect(code, contains('val field1: Map<Any, Any?>? = null'));
  });

  test('gen nested', () {
    final Class klass = Class(
      name: 'Outer',
      fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'Nested',
            isNullable: true,
          ),
          name: 'nested',
        )
      ],
    );
    final Class nestedClass = Class(
      name: 'Nested',
      fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'int',
            isNullable: true,
          ),
          name: 'data',
        )
      ],
    );
    final Root root = Root(
      apis: <Api>[],
      classes: <Class>[klass, nestedClass],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('data class Outer'));
    expect(code, contains('data class Nested'));
    expect(code, contains('val nested: Nested? = null'));
    expect(code, contains('fun fromMap(map: Map<String, Any?>): Outer'));
    expect(
        code,
        contains(
            'val nested: Nested? = (map["nested"] as? Map<String, Any?>)?.let'));
    expect(code, contains('Nested.fromMap(it)'));
    expect(code, contains('fun toMap(): Map<String, Any?>'));
  });

  test('gen one async Host Api', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
              type: const TypeDeclaration(
                baseName: 'Input',
                isNullable: false,
              ),
              name: 'arg',
            )
          ],
          returnType:
              const TypeDeclaration(baseName: 'Output', isNullable: false),
          isAsynchronous: true,
        )
      ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'String',
            isNullable: true,
          ),
          name: 'input',
        )
      ]),
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'String',
            isNullable: true,
          ),
          name: 'output',
        )
      ])
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('interface Api'));
    expect(code, contains('api.doSomething(argArg) {'));
    expect(code, contains('reply.reply(wrapResult(it))'));
  });

  test('gen one async Flutter Api', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
              type: const TypeDeclaration(
                baseName: 'Input',
                isNullable: false,
              ),
              name: '',
            )
          ],
          returnType:
              const TypeDeclaration(baseName: 'Output', isNullable: false),
          isAsynchronous: true,
        )
      ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'String',
            isNullable: true,
          ),
          name: 'input',
        )
      ]),
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'String',
            isNullable: true,
          ),
          name: 'output',
        )
      ])
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('class Api'));
    expect(code, matches('fun doSomething.*Input.*callback.*Output.*Unit'));
  });

  test('gen one enum class', () {
    final Enum anEnum = Enum(
      name: 'Enum1',
      members: <String>[
        'one',
        'two',
      ],
    );
    final Class klass = Class(
      name: 'EnumClass',
      fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'Enum1',
            isNullable: true,
          ),
          name: 'enum1',
        ),
      ],
    );
    final Root root = Root(
      apis: <Api>[],
      classes: <Class>[klass],
      enums: <Enum>[anEnum],
    );
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('enum class Enum1(val raw: Int)'));
    expect(code, contains('ONE(0)'));
    expect(code, contains('TWO(1)'));
  });

  Iterable<String> makeIterable(String string) sync* {
    yield string;
  }

  test('header', () {
    final Root root = Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    final KotlinOptions swiftOptions = KotlinOptions(
      copyrightHeader: makeIterable('hello world'),
    );
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, startsWith('// hello world'));
  });

  test('generics - list', () {
    final Class klass = Class(
      name: 'Foobar',
      fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
              baseName: 'List',
              isNullable: true,
              typeArguments: <TypeDeclaration>[
                TypeDeclaration(baseName: 'int', isNullable: true)
              ]),
          name: 'field1',
        ),
      ],
    );
    final Root root = Root(
      apis: <Api>[],
      classes: <Class>[klass],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('data class Foobar'));
    expect(code, contains('val field1: List<Long?>'));
  });

  test('generics - maps', () {
    final Class klass = Class(
      name: 'Foobar',
      fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
              baseName: 'Map',
              isNullable: true,
              typeArguments: <TypeDeclaration>[
                TypeDeclaration(baseName: 'String', isNullable: true),
                TypeDeclaration(baseName: 'String', isNullable: true),
              ]),
          name: 'field1',
        ),
      ],
    );
    final Root root = Root(
      apis: <Api>[],
      classes: <Class>[klass],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('data class Foobar'));
    expect(code, contains('val field1: Map<String?, String?>'));
  });

  test('host generics argument', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration.voidDeclaration(),
              arguments: <NamedType>[
                NamedType(
                  type: const TypeDeclaration(
                      baseName: 'List',
                      isNullable: false,
                      typeArguments: <TypeDeclaration>[
                        TypeDeclaration(baseName: 'int', isNullable: true)
                      ]),
                  name: 'arg',
                )
              ])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('fun doit(arg: List<Long?>'));
  });

  test('flutter generics argument', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration.voidDeclaration(),
              arguments: <NamedType>[
                NamedType(
                  type: const TypeDeclaration(
                      baseName: 'List',
                      isNullable: false,
                      typeArguments: <TypeDeclaration>[
                        TypeDeclaration(baseName: 'int', isNullable: true)
                      ]),
                  name: 'arg',
                )
              ])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('fun doit(argArg: List<Long?>'));
  });

  test('host generics return', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration(
                  baseName: 'List',
                  isNullable: false,
                  typeArguments: <TypeDeclaration>[
                    TypeDeclaration(baseName: 'int', isNullable: true)
                  ]),
              arguments: <NamedType>[])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('fun doit(): List<Long?>'));
    expect(code, contains('wrapped["result"] = api.doit()'));
    expect(code, contains('reply.reply(wrapped)'));
  });

  test('flutter generics return', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration(
                  baseName: 'List',
                  isNullable: false,
                  typeArguments: <TypeDeclaration>[
                    TypeDeclaration(baseName: 'int', isNullable: true)
                  ]),
              arguments: <NamedType>[])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('fun doit(callback: (List<Long?>) -> Unit'));
    expect(code, contains('val result = it as List<Long?>'));
    expect(code, contains('callback(result)'));
  });

  test('host multiple args', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
        Method(
          name: 'add',
          arguments: <NamedType>[
            NamedType(
                name: 'x',
                type:
                    const TypeDeclaration(isNullable: false, baseName: 'int')),
            NamedType(
                name: 'y',
                type:
                    const TypeDeclaration(isNullable: false, baseName: 'int')),
          ],
          returnType: const TypeDeclaration(baseName: 'int', isNullable: false),
        )
      ])
    ], classes: <Class>[], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('fun add(x: Long, y: Long): Long'));
    expect(code, contains('val args = message as List<Any?>'));
    expect(
        code,
        contains(
            'val xArg = args[0].let { if (it is Int) it.toLong() else it as Long }'));
    expect(
        code,
        contains(
            'val yArg = args[1].let { if (it is Int) it.toLong() else it as Long }'));
    expect(code, contains('wrapped["result"] = api.add(xArg, yArg)'));
    expect(code, contains('reply.reply(wrapped)'));
  });

  test('flutter multiple args', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
        Method(
          name: 'add',
          arguments: <NamedType>[
            NamedType(
                name: 'x',
                type:
                    const TypeDeclaration(baseName: 'int', isNullable: false)),
            NamedType(
                name: 'y',
                type:
                    const TypeDeclaration(baseName: 'int', isNullable: false)),
          ],
          returnType: const TypeDeclaration(baseName: 'int', isNullable: false),
        )
      ])
    ], classes: <Class>[], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('val channel = BasicMessageChannel'));
    expect(code, contains('val result = it as Long'));
    expect(code, contains('callback(result)'));
    expect(code,
        contains('fun add(xArg: Long, yArg: Long, callback: (Long) -> Unit)'));
    expect(code, contains('channel.send(listOf(xArg, yArg)) {'));
  });

  test('return nullable host', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration(
                baseName: 'int',
                isNullable: true,
              ),
              arguments: <NamedType>[])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('fun doit(): Long?'));
  });

  test('return nullable host async', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration(
                baseName: 'int',
                isNullable: true,
              ),
              isAsynchronous: true,
              arguments: <NamedType>[])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('fun doit(callback: (Long?) -> Unit'));
  });

  test('nullable argument host', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration.voidDeclaration(),
              arguments: <NamedType>[
                NamedType(
                    name: 'foo',
                    type: const TypeDeclaration(
                      baseName: 'int',
                      isNullable: true,
                    )),
              ])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(
        code,
        contains(
            'val fooArg = args[0].let { if (it is Int) it.toLong() else it as? Long }'));
  });

  test('nullable argument flutter', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration.voidDeclaration(),
              arguments: <NamedType>[
                NamedType(
                    name: 'foo',
                    type: const TypeDeclaration(
                      baseName: 'int',
                      isNullable: true,
                    )),
              ])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('fun doit(fooArg: Long?, callback: () -> Unit'));
  });

  test('nonnull fields', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
              type: const TypeDeclaration(
                baseName: 'Input',
                isNullable: false,
              ),
              name: '',
            )
          ],
          returnType: const TypeDeclaration.voidDeclaration(),
        )
      ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(
            baseName: 'String',
            isNullable: false,
          ),
          name: 'input',
        )
      ]),
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    const KotlinOptions swiftOptions = KotlinOptions();
    generateKotlin(swiftOptions, root, sink);
    final String code = sink.toString();
    expect(code, contains('val input: String\n'));
  });
}
