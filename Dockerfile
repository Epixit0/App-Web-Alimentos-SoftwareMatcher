# Build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore ./MatcherApi.csproj
RUN dotnet publish ./MatcherApi.csproj -c Release -o /out

# Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /out .
ENV ASPNETCORE_URLS=http://0.0.0.0:5100
EXPOSE 5100
ENTRYPOINT ["dotnet", "MatcherApi.dll"]
