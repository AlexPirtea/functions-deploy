pwd:=$(shell pwd)
out_folder:=out/
w_dir=/app
publish_path:=$(w_dir)/$(out_folder)
dotnet:=docker run -v $(pwd):$(w_dir) -w $(w_dir) mcr.microsoft.com/dotnet/core/sdk:2.1 dotnet
az:=docker run -v $(pwd)/:$(w_dir) -w $(w_dir) microsoft/azure-cli az
package:=package.zip

publish:
	$(dotnet) publish -c Release -o $(publish_path)
clean_zip:
	rm -f $(pwd)/$(package)
zip: clean_zip publish
	cd $(out_folder) && \
	zip -r $(pwd)/$(package) *
push: zip
	. deploy/env && \
	$(az) login --service-principal \
		-u "$$client_id" \
		-p "$$client_secret" \
		--tenant "$$tenant_id" \
		--allow-no-subscriptions && \
	az functionapp deployment source config-zip \
		-g "$$resource_group" \
		-n "$$function_name" \
		-s "$$slot_name" \
		--src $(package)
config:
	. deploy/env && \
	$(az) login --service-principal \
		-u "$$client_id" \
		-p "$$client_secret" \
		--tenant "$$tenant_id" \
		--allow-no-subscriptions \
		> /dev/null && \
	az functionapp config appsettings \
		set -n "$$function_name" -g "$$resource_group" --settings \
		$$(cat deploy/settings)