{% set cats = ["Russian Blue", "Turkish angora", "Ragdoll","Siamese", "Persian", "Maine Coon", "Bengal"] %}


{%- for i in cats %}
    {%- if i != "Persian" %}
        {{ i }}
    {%-else %}
        I dont like {{ i }} 
    {%- endif %}
{%- endfor %}
