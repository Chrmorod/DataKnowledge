# Cloud Functions

## Eventos (*Cloud Storage*)

Aproximadamente cada segundo, el servidor de eventos generará sucesos para que el sistema los considere. Un ejemplo de evento puede ser el siguiente:

> _En un determinado momento, un usuario alquila un piso en la 'Avenida de Francia' al cliente 'Pedro Martínez' durante tres días_.

### Bucket

`gs://bigdataupv2022-airbnb_data/events`

```
events
│   
├── raw/
│   ├── <datetime.utcnow().date().isoformat()>/
│   ...
│
└── reports/
    │
    ├── topTen/
    ├── royalties/
    └── usage/
```

### Ejemplo

```json
{
    "eventId": "0671a422-7b2f-4c7b-a132-be8db516c4cf", 
    "tenantId": "airbnb", 
    "eventTime": "2022-12-30T18:34:06.944202504+01:00", 
    "processTime": "2022-12-30T18:34:24.944202504+01:00", 
    "resourceId": "RES.004", 
    "userId": "USR.004",
    "countryCode": "PT", 
    "duration": 234, 
    "itemPrice": 37.56, 
    "externalId": null, 
    "created": "2022-12-30T17:34:07.290915"
} 
```

## Recursos (*Fire Store*)

### Estructura

### Ejemplo

## Usuarios (*Fire Store*)

### Estructura

### Ejemplo