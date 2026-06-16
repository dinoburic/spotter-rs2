FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 5126

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["Spotter.WebAPI/Spotter.WebAPI.csproj", "Spotter.WebAPI/"]
COPY ["Spotter.Services/Spotter.Services.csproj", "Spotter.Services/"]
COPY ["Spotter.Model/Spotter.Model.csproj", "Spotter.Model/"]
COPY ["Spotter.Common.Services/Spotter.Common.Services.csproj", "Spotter.Common.Services/"]
RUN dotnet restore "Spotter.WebAPI/Spotter.WebAPI.csproj"
COPY . .
WORKDIR "/src/Spotter.WebAPI"
RUN dotnet build "Spotter.WebAPI.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Spotter.WebAPI.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Spotter.WebAPI.dll"]
