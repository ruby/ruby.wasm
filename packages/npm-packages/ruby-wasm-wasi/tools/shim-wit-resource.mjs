import ts from "typescript"
import path from "path"

const findTopLevelStatement = (options) => {
    const DEFAULT_COMPILER_OPTIONS = {
        noEmit: true,
        noEmitOnError: true,
        noImplicitAny: true,
        target: ts.ScriptTarget.ES5,
        module: ts.ModuleKind.CommonJS
    };
    const program = ts.createProgram([options.sourceFile], DEFAULT_COMPILER_OPTIONS)
    for (const sourceFile of program.getSourceFiles()) {
        if (options.sourceFile != sourceFile.fileName) continue
        for (const statement of sourceFile.statements) {
            if (options.condition(statement)) {
                return [statement, sourceFile];
            }
        }
    }
}

class Parameter {
    /**
     * @param {string} name
     * @param {string} type
     */
    constructor(name, type) {
        this.name = name
        this.type = type
    }
}


class Method {
    /**
     * @param {string} name
     * @param {Parameter[]} parameters
     * @param {string} returnType
     */
    constructor(name, parameters, returnType) {
        this.name = name
        this.parameters = parameters
        this.returnType = returnType
    }

    hasTypeInSignature(targetType) {
        for (const parameter of this.parameters) {
            if (parameter.type == targetType) {
                return true
            }
        }
        return this.returnType == targetType
    }
}

/**
 * @param {ts.ClassDeclaration} classDecl
 * @param {ts.SourceFile} sourceFile
 * @returns {Method[]}
 */
const findMethodDecls = (classDecl, sourceFile) => {
    const result = []
    for (const member of classDecl.members) {
        if (member.kind != ts.SyntaxKind.MethodDeclaration) {
            continue
        }
        /**
         * @type {ts.MethodDeclaration}
         */
        const method = member
        const name = method.name.getText(sourceFile)
        const parameters = method.parameters.map((parameter) => {
            return new Parameter(parameter.name.getText(sourceFile), parameter.type.getText(sourceFile))
        })
        const returnType = method.type?.getText(sourceFile) ?? "void"
        result.push(new Method(name, parameters, returnType))
    }
    return result
}

class CodeGenerator {

    /**
     * @param {Method[]} methods
     */
    emit(methods) {
        let result = `
        export function shimExports<Wrapper, Imports>(
            liftUp: (result: number) => Wrapper,
            liftDown: (wrapper: Wrapper) => number,
            imports: Imports
        ): Imports {
            const newImports = Object.assign({}, imports)
        `
        for (const method of methods) {
            if (!method.hasTypeInSignature("RbAbiValue")) {
                continue
            }
            result += `
            newImports.${method.name} = (...args: [${method.parameters.map((parameter) => parameter.type).join(", ")}]): ${method.returnType} => {
                const result = liftDown(imports.${method.name}(${method.parameters.map((parameter) => parameter.name).join(", ")}))
                return liftUp(result)
            }
            `
        }

        result += `
            return newImports
        }
        `
        return result
    }
}

const main = async () => {
    const dirname = path.dirname(new URL(import.meta.url).pathname);
    const guest = path.resolve(dirname, "../src/bindgen/rb-abi-guest.d.ts")
    /**
     * @type {[ts.ClassDeclaration, ts.SourceFile]}
     */
    const [RbAbiGuest, sourceFile] = findTopLevelStatement(
        {
            sourceFile: guest,
            condition: (statement) => {
                return statement.kind == ts.SyntaxKind.ClassDeclaration && statement.name.text == "RbAbiGuest"
            }
        }
    )

    if (RbAbiGuest == null) {
        console.log("RbAbiGuest not found")
        return
    }

    const methods = findMethodDecls(RbAbiGuest, sourceFile)
    const generator = new CodeGenerator()
    console.log(generator.emit(methods))
}

main()
