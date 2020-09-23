#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/core/aspnet:3.1-buster-slim AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/core/sdk:3.1-buster AS build
WORKDIR /src
COPY ["SampleHerokuContainer.csproj", ""]
RUN dotnet restore "./SampleHerokuContainer.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "SampleHerokuContainer.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "SampleHerokuContainer.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "SampleHerokuContainer.dll"]


# NuGet restore
FROM mcr.microsoft.com/dotnet/core/sdk:3.1-buster AS build
WORKDIR /src
COPY *.sln .

COPY SampleHerokuContainer/*.csproj  SampleHerokuContainer/


RUN dotnet restore
COPY . .

# testing
FROM build AS testing
WORKDIR /src/SampleHerokuContainer.Api
RUN dotnet build
WORKDIR /src/SampleHerokuContainer.Test
RUN dotnet test

# publish
FROM build AS publish
WORKDIR /src/SampleHerokuContainer.Api
RUN dotnet publish -c Release -o /src/publish

FROM mcr.microsoft.com/dotnet/core/aspnet:3.1 AS runtime
WORKDIR /app
COPY --from=publish /src/publish .


# heroku uses the following
CMD ASPNETCORE_URLS=http://*:$PORT dotnet SampleHerokuContainer.Api.dll