_getAttr(h5io,key) = read(attributes(h5io)[key])[1]
_setAttr(h5io,key,value) = write_attribute(h5io, key, value)

@enum ImgType TwoD = 2 ThreeD = 3
Base.String(imgtype::ImgType) = "$(Int(imgtype))D"
