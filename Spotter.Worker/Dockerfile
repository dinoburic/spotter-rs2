FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["Spotter.Worker/Spotter.Worker.csproj", "Spotter.Worker/"]
COPY ["Spotter.Model/Spotter.Model.csproj", "Spotter.Model/"]
COPY ["Spotter.Services/Spotter.Services.csproj", "Spotter.Services/"]
COPY ["Spotter.Common.Services/Spotter.Common.Services.csproj", "Spotter.Common.Services/"]
RUN dotnet restore "Spotter.Worker/Spotter.Worker.csproj"
COPY . .
WORKDIR "/src/Spotter.Worker"
RUN dotnet build "Spotter.Worker.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Spotter.Worker.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Spotter.Worker.dll"]
