FROM circleci/python:3.8

USER root

WORKDIR /appimage

# Create python3.8 based AppImage
RUN python -m pip install python_appimage
RUN python -m python_appimage build local -d ./python3.8.AppImage -p /usr/local/bin/python

# Install Xun to image
RUN ./python3.8.AppImage --appimage-extract
RUN ./squashfs-root/AppRun -m pip install git+https://github.com/equinor/xun.git

# Change AppRun so that it launches Xun
RUN sed -i -e 's|/opt/python3.8/bin/python3.8|/usr/bin/xun|g' ./squashfs-root/AppRun

# Edit the desktop file
RUN mv squashfs-root/usr/share/applications/python3.8.6.desktop squashfs-root/usr/share/applications/xun.desktop
RUN sed -i -e 's|^Name=.*|Name=Xun|g' squashfs-root/usr/share/applications/*.desktop
RUN sed -i -e 's|^Exec=.*|Exec=Xun|g' squashfs-root/usr/share/applications/*.desktop
RUN sed -i -e 's|^Icon=.*|Icon=xun|g' squashfs-root/usr/share/applications/*.desktop
RUN rm squashfs-root/*.desktop
RUN cp squashfs-root/usr/share/applications/*.desktop squashfs-root/

# Setup icon
RUN mv squashfs-root/python.png squashfs-root/xun.png

# Store our Xun AppImage to different folder
RUN mv squashfs-root squashfs-root-xun
ENV VERSION 0.1

# Convert back into an AppImage
RUN wget -c https://github.com/$(wget -q https://github.com/probonopd/go-appimage/releases -O - | grep "appimagetool-.*-x86_64.AppImage" | head -n 1 | cut -d '"' -f 2)
RUN chmod +x appimagetool-*.AppImage
RUN ./appimagetool-587-x86_64.AppImage --appimage-extract

# The following line does not work quite yet due to https://github.com/probonopd/go-appimage/issues/30
# ./appimagetool-*-x86_64.AppImage deploy squashfs-root/usr/share/applications/taguette.desktop
RUN ./squashfs-root/AppRun squashfs-root-xun/

# Cleanup
RUN rm -r squashfs-root-xun/
RUN rm -r squashfs-root/
RUN rm appimagetool-587-x86_64.AppImage
RUN rm python3.8.AppImage

# Upload later for now:
#docker cp <container-id>:/appimage/Xun-0.1-x86_64.AppImage ./appimage
