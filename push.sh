TAG=5.5.7
# commit current running images 
#docker commit fusionpbx michaelfangtw/fusionpbx-docker:$TAG
#tag 
docker tag dc/fusionpbx:$TAG najeebkhan12/fusionpbx:$TAG
docker push najeebkhan12/fusionpbx:$TAG


