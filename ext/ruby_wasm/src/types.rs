use magnus::{exception, wrap, Error, RArray, Symbol};

#[wrap(class = "ComponentizerExt::ValType")]
pub(crate) struct ValType(wasm_inject::walrus::ValType);

impl ValType {
    pub(crate) fn new(ty: Symbol) -> Result<Self, Error> {
        let ty = match ty.to_string().as_str() {
            "i32" => wasm_inject::walrus::ValType::I32,
            "i64" => wasm_inject::walrus::ValType::I64,
            "f32" => wasm_inject::walrus::ValType::F32,
            "f64" => wasm_inject::walrus::ValType::F64,
            "v128" => wasm_inject::walrus::ValType::V128,
            "externref" => wasm_inject::walrus::ValType::Externref,
            "funcref" => wasm_inject::walrus::ValType::Funcref,
            _ => {
                return Err(Error::new(
                    exception::standard_error(),
                    format!("invalid type: {}", ty),
                ))
            }
        };
        Ok(Self(ty))
    }

    pub(crate) fn vec_from_rarray(tys: RArray) -> Result<Vec<wasm_inject::walrus::ValType>, Error> {
        let tys = unsafe { tys.as_slice() }
            .iter()
            .map(|v| -> Result<wasm_inject::walrus::ValType, Error> {
                let sym = Symbol::from_value(*v).ok_or_else(|| {
                    Error::new(
                        exception::standard_error(),
                        format!("invalid type: {}", v),
                    )
                })?;
                let ty = ValType::new(sym)?;
                Ok(ty.0)
            })
            .collect::<Result<Vec<_>, _>>()?;
        Ok(tys)
    }
}
