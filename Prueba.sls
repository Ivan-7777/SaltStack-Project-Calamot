crear_archivo_de_prueba:
 file.managed:
   - name: /tmp/hola.txt
   - contents: |
     ¡Salt funciona correctamente!
     Este archivo ha sido creado desde el master
