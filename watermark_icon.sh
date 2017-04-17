export PATH=/opt/local/bin/:/opt/local/sbin:$PATH:/usr/local/bin:

convertPath=`which convert`

if [ ! -f ${convertPath} ]; then
echo "==============
WARNING: 你需要先安装 ImageMagick！！！！:
brew install imagemagick
=============="
exit 0;
fi


commit=`git rev-parse --short HEAD`
branch=`git rev-parse --abbrev-ref HEAD`
buildNumber=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}"`
caption="${buildNumber} \n${branch}\n${commit}"

echo "caption: ${caption}"
echo "product_path: ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/"

# Release 不执行
echo "Configuration: $CONFIGURATION"
if [ ${CONFIGURATION} = "Release" ]; then
exit 0;
fi

function generateIcon() {
    originalImg=$1

    cd "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

    # 验证存在性
    if [[ ! -f ${originalImg} || -z ${originalImg} ]]; then
    return;
    fi

    # 进入编译后的工程目录
    cd "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/"

    # 添加高斯模糊
    convert ${originalImg} -blur 10x8 blur-original.png

    # 截取下部分
    width=`identify -format %w ${originalImg}`
    height=`identify -format %h ${originalImg}`
    height_0=`expr ${height} / 2`
    height_1=$((${height} - ${height_0}))
    convert blur-original.png -crop ${width}x${height_0}+0+${height_1} crop-blur-original.png

    # 加字
    point_size=$(((8 * $width) / 58))

    convert -background none -fill white -pointsize ${point_size} -gravity center caption:"${caption}" crop-blur-original.png +swap -composite label.png

    # 合成
    composite -geometry +0+${height_0} label.png ${originalImg} ${originalImg}

    # 清除文件
    rm blur-original.png
    rm crop-blur-original.png
    rm label.png
}

icon_count=`/usr/libexec/PlistBuddy -c "Print CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles" "${CONFIGURATION_BUILD_DIR}/${INFOPLIST_PATH}" | wc -l`


# Array {
# AppIcon29x29
# AppIcon40x40
# AppIcon60x60
# }
# -2 的原因是因为输出是五行
real_icon_index=$((${icon_count} - 2))

# ========= for =========
for ((i=0; i<$real_icon_index; i++)); do
# 去 plist 中顺着路径找到 icon 名
icon=`/usr/libexec/PlistBuddy -c "Print CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:$i" "${CONFIGURATION_BUILD_DIR}/${INFOPLIST_PATH}"`

echo "icon: ${icon}"

if [[ $icon == *.png ]] || [[ $icon == *.PNG ]]
then
generateIcon $icon
else
generateIcon "${icon}.png"
generateIcon "${icon}@2x.png"
generateIcon "${icon}@3x.png"
fi

done
# ========= end for =========
