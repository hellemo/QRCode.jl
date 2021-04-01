struct QRCode{T}
    s::String
    eclevel::T
end
QRCode(s) = QRCode(s, Medium())

function Base.show(io::IO, ::MIME"text/plain", qrc::QRCode)
    qrm = qrcode(qrc.s, qrc.eclevel)
    print(io, UnicodePlots.heatmap(qrm;
                        padding=0,margin=0,border=:none,
                        width=size(qrm,2),colormap=[(1,1,1),(0,0,0)],labels=false))
end

function Base.show(io::IO, ::MIME"image/png", qrc::QRCode)
    write(io, qrpng(qrc))
end

function Base.show(io::IO, ::MIME"image/svg+xml", qrc::QRCode)
    write(io, qrsvg(qrc))
end

function qrpng(qrc::QRCode)
    qrm = qrcode(qrc.s, qrc.eclevel)
    scale = Int(round(200/size(qrm,1)))
    qrm = Gray.(repeat(.!qrm, inner=(scale,scale)))
    png = IOBuffer()
    save(Stream(format"PNG", png), qrm)
    return take!(png)
end

function qrsvg(qrc::QRCode, sz=5cm)
    svg = IOBuffer()
    composition = composesvg(qrc, sz)
    composition |> SVG(svg, sz, sz)
    return take!(svg)
end

function composesvg(qrc::QRCode, sz=5cm)
    qrm = qrcode(qrc.s, qrc.eclevel)
    I, J = size(qrm)
    composition = compose(context(), fill("black"),
    ((context((j-1)/I,(i-1)/J,1/J + 1e-3,1/I + 1e-3), rectangle()) 
        for i=1:size(qrm,1),j=1:size(qrm,2) if qrm[i,j]==1 )...
    )
end

function save(fn, qrc::QRCode, sz=5cm)
    ext = lowercase(last(splitext(fn))) 
    if ext == ".svg"
        draw(SVG(fn), composesvg(qrc, sz))
    else
        @error "File extension $ext not supported"
    end
end