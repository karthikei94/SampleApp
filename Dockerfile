# Learn about building .NET container images:
# https://github.com/dotnet/dotnet-docker/blob/main/samples/README.md
FROM mcr.microsoft.com/dotnet/aspnet:9.0-azurelinux3.0 AS base
#- USER $APP_UID
WORKDIR /app
EXPOSE 80
EXPOSE 443
# EXPOSE 8080
# EXPOSE 8081

# # this stage is used by VS for fast local debugging; it does not appear in the final image
# FROM base AS debug
# RUN tdnf install -y procps-ng # <-- Install tools needed for debugging (e.g. the `pidof` command)

FROM mcr.microsoft.com/dotnet/sdk:9.0-azurelinux3.0 AS build
ARG BUILD_CONFIGURATION=Development
WORKDIR /src
COPY ["src/SampleApp.Api/SampleApp.Api.csproj", "SampleApp.Api/"]
RUN dotnet restore "./SampleApp.Api/SampleApp.Api.csproj"
COPY ./src .
RUN pwd
RUN dir -s
WORKDIR "/src/SampleApp.Api"
RUN dotnet build "./SampleApp.Api.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./SampleApp.Api.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
# + # Make sure non-root user is enabled after the debug stage so that we have permission to install the debug dependencies
# + USER $APP_UID
ENTRYPOINT ["dotnet", "SampleApp.Api.dll"]